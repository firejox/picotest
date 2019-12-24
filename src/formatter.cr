require "colorize"
require "./context"

struct PicoTest
  abstract struct Formatter
    def new_scope
      yield
    end

    def report(context)
    end

    def finish
    end

    def before_example(description)
    end

    def flush_to(out_io : IO, err_io : IO)
    end
  end
end
