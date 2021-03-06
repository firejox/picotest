require "colorize"
require "time"
require "./error"

struct PicoTest
  abstract struct Context
    getter :description
    getter :file
    getter :line

    def initialize(@description : String, @file : String, @line : Int32)
    end
  end

  struct ExampleGroup < Context
    @parent : Pointer(self)

    def initialize(parent : Pointer(self), description : String, file : String, line : Int32)
      super(description, file, line)
      @parent = parent
    end

    def self.color(obj)
      obj.colorize(:white)
    end
  end

  private struct Pass; end

  private struct Failed; end

  private struct Error; end

  private struct Pending; end

  struct Example(T) < Context
    EXAMPLE_COLORS = {
      Pass:    :light_green,
      Pending: :light_gray,
      Failed:  :red,
      Error:   :red,
    }

    property exception : (UnhandledError | AssertionError | Nil)
    getter :duration
    @parent : Pointer(ExampleGroup)

    def initialize(parent : Pointer(ExampleGroup), duration : Time::Span, description : String, file : String, line : Int32)
      super(description, file, line)
      @duration = duration
      @parent = parent
    end

    def backtrace
      yield @exception
      yield self
      it = @parent
      until it.null?
        yield it.value
        it = it.value.@parent
      end
    end

    def self.color(obj)
      {% for key, value in EXAMPLE_COLORS %}
        {% if T.id.ends_with?(key.stringify) %}
          obj.colorize {{ value }}
        {% end %}
      {% end %}
    end
  end
end
