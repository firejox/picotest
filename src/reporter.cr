require "./list"
require "./macros"
require "./description"
require "colorize"

include PicoTest::Macros

struct PicoTest::Reporter
  @indent = 0
  @desc_stack = List.new
  @passed = 0
  @failed = 0
  @error = 0
  @pending = 0

  def initialize(@io : IO)
  end

  # initialize description stack
  protected def init_stack
    @desc_stack.init
  end

  def describe_scope(description, file, line)
    node = PicoTest::Description.new(:"describe", description, file, line)
    push_description pointerof(node.@link)
    print_top_description color: :white, prefix: :"", suffix: :""

    yield

    pop_description
  end

  def it_scope(description, file, line)
    node = PicoTest::Description.new(:"it", description, file, line)
    push_description pointerof(node.@link)
    yield
  rescue ex : PicoTest::AssertionError
    print_top_description color: :red, prefix: :"- ", suffix: :" [Failed]"
    print_backtrace(ex.message, ex.file, ex.line)
    @failed += 1
  rescue ex
    print_top_description color: :red, prefix: :"- ", suffix: :" [Error]"
    print_backtrace("Unhandled exception caught: #{ex}", file, line)
    @error += 1
  else
    print_top_description color: :light_green, prefix: :"- ", suffix: :""
    @passed += 1
  ensure
    pop_description
  end

  def pending_scope(description, file, line)
    node = PicoTest::Description.new(:"pending", description, file, line)
    push_description pointerof(node.@link)
    print_top_description color: :light_gray, prefix: :"- ", suffix: :" [Pending]"
    pop_description
    @pending += 1
  end

  # push description stack
  private def push_description(desc_ptr)
    @indent += 1
    @desc_stack.unshift desc_ptr
  end

  # pop description stack
  private def pop_description
    @indent -= 1
    @desc_stack.shift
  end

  def print_backtrace(message, file, line)
    @io.printf "%#{@indent * 2 + 4}s#{message}\n", ""
    @io.printf "%#{@indent * 2 + 10}sfrom #{file}:#{line}\n", ""

    @desc_stack.each do |it|
      desc_ptr = container_of(it, PicoTest::Description, @link)
      @io.printf "%#{@indent * 2 + 10}sfrom #{desc_ptr.value.file}:#{desc_ptr.value.line} - #{desc_ptr.value.dsl_type} \"#{desc_ptr.value.description}\"\n", ""
    end
  end

  def print_top_description(color, prefix, suffix)
    desc_ptr = container_of(@desc_stack.first, PicoTest::Description, @link)
    info = "#{prefix}#{desc_ptr.value.description}#{suffix}"

    @io.printf "%#{@indent * 2}s%s\n", "", info.colorize(color)
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
