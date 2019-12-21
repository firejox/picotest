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
    @formatter.push
    @formatter.report { node }

    yield

    @formatter.pop
  end

  def it_scope(description, file, line)
    @formatter.push
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
  ensure
    @formatter.pop
  end

  def pending_scope(description, file, line)
    node = Example(Pending).new(@top_node, description, file, line)
    @formatter.push
    @formatter.report { node }
    @formatter.pop
    @pending += 1
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
