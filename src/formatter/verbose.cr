require "../context"
require "../formatter"

struct PicoTest
  struct Example(T)
    def report_description(klass : VerboseFormatter.class)
      {% if T == Pass %}
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

    def report(context : ExampleGroup)
      @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", typeof(context).color(context.description)
    end

    def report(context : Example(Pass))
      @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", typeof(context).color(context.report_description(typeof(self)))
    end

    def report(context : Example(Pending))
      @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", typeof(context).color(context.report_description(typeof(self)))
    end

    macro error_backtrace(context)
      {{context}}.backtrace do |obj|
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

    def report(context : Example(Failed))
      @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", typeof(context).color(context.report_description(typeof(self)))
      error_backtrace(context)
    end

    def report(context : Example(Error))
      @io.printf "%#{@indent * INDENT_SPACE}s%s\n", "", typeof(context).color(context.report_description(typeof(self)))
      error_backtrace(context)
    end

    def finish
      @io.puts
    end

    def before_example(@last_description)
    end

    def flush_to(out_io : IO, err_io : IO)
      @io.to_s(out_io) if @io.is_a?(IO::Memory) && @io != out_io
    end
  end
end
