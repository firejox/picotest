require "colorize"
require "time"
require "./context"
require "./formatter"

struct PicoTest::Spec
  @passed = 0
  @failed = 0
  @error = 0
  @pending = 0

  def initialize(@io : IO, @formatter : Formatter)
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
        node = Example(Failed).new(@top_node, description, file, line)
        node.exception = ex
        @formatter.report(node)
        @failed += 1
      rescue ex
        elapse = Time.monotonic - start
        @spec_time += elapse
        node = Example(Error).new(@top_node, description, file, line)
        node.exception = PicoTest::UnhandledError.new(ex, file, line)
        @formatter.report(node)
        @error += 1
      else
        elapse = Time.monotonic - start
        @spec_time += elapse
        node = Example(Pass).new(@top_node, description, file, line)
        @formatter.report(node)
        @passed += 1
      end
    end
  end

  private def pending_internal(description, file, line)
    @formatter.new_scope do
      node = Example(Pending).new(@top_node, description, file, line)
      @formatter.report(node)
      @pending += 1
    end
  end

  private def self_pointer
    (->self.itself).closure_data.as(Pointer(self))
  end

  def flush_to(target : IO)
    @io.to_s(target) if @io.is_a?(IO::Memory)
  end

  struct Runner
    @@global_runner = new(STDOUT)

    def initialize(@io : IO)
      @passed = 0
      @failed = 0
      @error = 0
      @pending = 0
      @total_time = Time::Span.zero
    end

    # :nodoc:
    def new_spec
      Spec.new(@io, VerboseFormatter.new(@io))
    end

    # :nodoc:
    def report(spec_ptr : Spec*)
      @passed += spec_ptr.value.@passed
      @failed += spec_ptr.value.@failed
      @error += spec_ptr.value.@error
      @pending += spec_ptr.value.@pending
      @total_time += spec_ptr.value.@spec_time

      spec_ptr.value.flush_to(@io)
    end

    def print_statistics_and_exit
      total = @passed + @failed + @error + @pending
      status = "#{total} examples, #{@failed} failures, #{@error} errors, #{@pending} pendings"

      @io.puts "Finished in #{typeof(self).to_human(@total_time)}"
      if @failed == 0 && @error == 0
        @io.puts status.colorize(:light_green)
      else
        @io.puts status.colorize(:red)
        abort
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

    def self.global_runner
      with @@global_runner yield
    end

    at_exit do
      Runner.global_runner do
        print_statistics_and_exit
      end
    end
  end
end
