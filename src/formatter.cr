require "colorize"
require "./context"

struct PicoTest
  abstract struct Formatter
    def new_scope
      yield
    end

    def report(&)
    end

    def finish
    end

    def before_example(&)
    end
  end

  struct Example(T)
    def report_description(klass : VerboseFormatter.class)
      {% if T == Pass || T == None %}
        "- #{@description}"
      {% elsif T == Failed %}
        "- #{@description} [Failed]"
      {% elsif T == Error %}
        "- #{@description} [Error]"
      {% elsif T == Pending %}
        "- #{@description} [Pending]"
      {% else %}
        {% raise "Invalid example type #{T}" %}
      {% end %}
    end
  end

  struct VerboseFormatter < Formatter
    INDENT_SPACE       =  2
    EXCEPTION_INDENT   =  4
    STACK_TRACE_INDENT = 10

    @last_description : String? = nil

    def initialize(@io : IO)
      @indent = 0
    end

    def new_scope
      @indent += 1
      yield
    ensure
      @indent -= 1
    end

    def report
      context = yield
      case context
      when ExampleGroup
        @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", context.description.colorize(:white)
      when Example(Pass)
        @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", context.report_description(typeof(self)).colorize(:light_green)
      when Example(Pending)
        @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", context.report_description(typeof(self)).colorize(:light_gray)
      when Example(Failed), Example(Error)
        @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", context.report_description(typeof(self)).colorize(:red)

        context.backtrace do |obj|
          case obj
          when UnhandledError
            @io.printf "%#{@indent * INDENT_SPACE + EXCEPTION_INDENT}s%s\n", "", obj.description
          when AssertionError
            @io.printf "%#{@indent * INDENT_SPACE + EXCEPTION_INDENT}s%s\n", "", obj.description
            @io.printf "%#{@indent * INDENT_SPACE + STACK_TRACE_INDENT}sfrom %s:%-4d|\n", "", obj.file, obj.line
          when Example
            @io.printf "%#{@indent * INDENT_SPACE + STACK_TRACE_INDENT}sfrom %s:%-4d|   it %s\n", "", obj.file, obj.line, obj.description
          when ExampleGroup
            @io.printf "%#{@indent * INDENT_SPACE + STACK_TRACE_INDENT}sfrom %s:%-4d|   describe %s\n", "", obj.file, obj.line, obj.description
          end
        end
      end
    end

    def finish
      @io.puts
    end

    def before_example
      @last_description = yield
    end
  end
end
