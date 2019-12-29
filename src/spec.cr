require "colorize"
require "time"
require "channel"
require "mutex"
require "./context"
require "./formatter/**"

struct PicoTest::Spec
  @passed = 0
  @failed = 0
  @error = 0
  @pending = 0

  def initialize(@formatter : Formatter)
    @top_node = Pointer(ExampleGroup).null
    @spec_time = Time::Span.zero
  end

  private def describe_internal(description, file, line)
    node = ExampleGroup.new(@top_node, description, file, line)
    @top_node = pointerof(node)

    @formatter.new_scope do
      @formatter.report(node)
      yield
    end

    @top_node = @top_node.value.@parent
  end

  private def it_internal(description, file, line)
    @formatter.new_scope do
      start = Time.monotonic
      begin
        yield
      rescue ex : PicoTest::AssertionError
        elapse = Time.monotonic - start
        @spec_time += elapse
        node = Example(Failed).new(@top_node, elapse, description, file, line)
        node.exception = ex
        @formatter.report(node)
        @failed += 1
      rescue ex
        elapse = Time.monotonic - start
        @spec_time += elapse
        node = Example(Error).new(@top_node, elapse, description, file, line)
        node.exception = PicoTest::UnhandledError.new(ex, file, line)
        @formatter.report(node)
        @error += 1
      else
        elapse = Time.monotonic - start
        @spec_time += elapse
        node = Example(Pass).new(@top_node, elapse, description, file, line)
        @formatter.report(node)
        @passed += 1
      end
    end
  end

  private def pending_internal(description, file, line)
    @formatter.new_scope do
      node = Example(Pending).new(@top_node, Time::Span.zero, description, file, line)
      @formatter.report(node)
      @pending += 1
    end
  end

  private def self_pointer
    (->self.itself).closure_data.as(Pointer(self))
  end

  def flush_to(out_io : IO, err_io : IO)
    total = @passed + @failed + @error + @pending
    return if total == 0

    @formatter.finish
    @formatter.flush_to out_io, err_io
  end

  struct Runner
    def initialize(@io : IO)
      @err_out = IO::Memory.new

      @passed = 0
      @failed = 0
      @error = 0
      @pending = 0

      @total_time = Time::Span.zero

      @async_count = 0
      @async_spec_finish = Channel(Nil).new
      @report_barrier = Channel(Nil).new
      @mutex = Mutex.new Mutex::Protection::Unchecked
    end

    def async_spec_start
      @async_count += 1
    end

    def spec(sync = true)
      spec = if sync
               Spec.new(DotFormatter.new(@io, @err_out))
             else
               out_io = IO::Memory.new
               err_io = IO::Memory.new
               Spec.new(DotFormatter.new(out_io, err_io))
             end

      with spec yield

      add_report pointerof(spec), sync
    end

    # :nodoc:
    def add_report(spec_ptr : Spec*, sync = true)
      @report_barrier.receive? unless sync

      @mutex.synchronize do
        @passed += spec_ptr.value.@passed
        @failed += spec_ptr.value.@failed
        @error += spec_ptr.value.@error
        @pending += spec_ptr.value.@pending
        @total_time += spec_ptr.value.@spec_time

        spec_ptr.value.flush_to(@io, @err_out)
      end

      @async_spec_finish.receive? unless sync
    end

    def succeeded?
      @failed == 0 && @error == 0
    end

    def print_statistics
      sync_spec_time = @total_time
      elapse = Time.measure do
        @report_barrier.close
        @async_count.times do
          @async_spec_finish.send nil
        end
      end

      total = @passed + @failed + @error + @pending

      return if total == 0

      @io.puts
      @err_out.to_s(@io)
      @io.puts

      status = "#{total} examples, #{@failed} failures, #{@error} errors, #{@pending} pendings"

      @io.puts "Finished in #{typeof(self).to_human(sync_spec_time + elapse)}"
      @io.puts "Total spec time: #{typeof(self).to_human(@total_time)}"
      if succeeded?
        @io.puts status.colorize(:light_green)
      else
        @io.puts status.colorize(:red)
      end
    end

    def self.to_human(span : Time::Span)
      if span < 1.millisecond
        "#{(span.total_milliseconds*1000).round.to_i} µs"
      elsif span < 1.second
        "#{span.total_milliseconds.round(2)} ms"
      elsif span < 1.minute
        "#{span.total_seconds.round(2)} s"
      elsif span < 1.hour
        "#{span.minutes} m #{span.seconds} s"
      else
        "#{span.total_hours.to_i} h #{span.minutes} m #{span.seconds} s"
      end
    end
  end
end
