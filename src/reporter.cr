require "colorize"
require "./context"
require "./formatter"

struct PicoTest::Reporter
  @indent = 0
  @passed = 0
  @failed = 0
  @error = 0
  @pending = 0

  def initialize(@io : IO)
    @top_node = Pointer(ExampleGroup).null
    @formatter = VerboseFormatter.new(@io)
  end

  def describe_scope(description, file, line)
    node = ExampleGroup.new(@top_node, description, file, line)
    @top_node = pointerof(node)

    @formatter.new_scope do
      @formatter.report { node }
      yield
    end

    @top_node = @top_node.value.@parent
  end

  def it_scope(description, file, line)
    @formatter.new_scope do
      begin
        yield
      rescue ex : PicoTest::AssertionError
        node = Example(Failed).new(@top_node, description, file, line)
        node.exception = ex
        @formatter.report { node }
        @failed += 1
      rescue ex
        node = Example(Error).new(@top_node, description, file, line)
        node.exception = PicoTest::UnhandledError.new(ex, file, line)
        @formatter.report { node }
        @error += 1
      else
        node = Example(Pass).new(@top_node, description, file, line)
        @formatter.report { node }
        @passed += 1
      end
    end
  end

  def pending_scope(description, file, line)
    @formatter.new_scope do
      node = Example(Pending).new(@top_node, description, file, line)
      @formatter.report { node }
      @pending += 1
    end
  end

  def print_statistics_and_exit
    total = @passed + @failed + @error + @pending
    status = "#{total} examples, #{@failed} failures, #{@error} errors, #{@pending} pendings"
    if @failed == 0 && @error == 0
      @io.puts status.colorize(:light_green)
    else
      @io.puts status.colorize(:red)
      abort
    end
  end
end
