require "colorize"
require "../context"
require "../formatter"

struct PicoTest
  struct DotFormatter < Formatter
    STACK_TRACE_INDENT = 8

    def initialize(@io : IO, @error : IO)
    end

    def report(context : Example(Pass))
      @io.print typeof(context).color('.')
    end

    def report(context : Example(Pending))
      @io.print typeof(context).color('P')
    end

    macro error_backtrace(context)
      {{context}}.backtrace do |obj|
        case obj
        when UnhandledError
          @error.puts obj.description
        when AssertionError
          @error.puts obj.description
          @error.printf "%#{STACK_TRACE_INDENT}sfrom %s:%-4d|\n", "", obj.file, obj.line
        when Example
          @error.printf "%#{STACK_TRACE_INDENT}sfrom %s:%-4d|   it %s\n", "", obj.file, obj.line, obj.description
        when ExampleGroup
          @error.printf "%#{STACK_TRACE_INDENT}sfrom %s:%-4d|   describe %s\n", "", obj.file, obj.line, obj.description
        end
      end
      @error.puts
    end

    def report(context : Example(Failed))
      @io.print typeof(context).color('F')
      error_backtrace(context)
    end

    def report(context : Example(Error))
      @io.print typeof(context).color('E')
      error_backtrace(context)
    end

    def flush_to(out_io : IO, err_io : IO)
      @io.to_s(out_io) if @io.is_a?(IO::Memory) && @io != out_io
      @error.to_s(err_io) if @error.is_a?(IO::Memory) && @error != err_io
    end
  end
end
