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
  end

  private struct None; end
  private struct Pass; end
  private struct Failed; end
  private struct Error; end
  private struct Pending; end

  struct Example(T) < Context

    property exception : (UnhandledError | AssertionError | Nil)
    @parent : Pointer(ExampleGroup)

    def initialize(parent : Pointer(ExampleGroup), description : String, file : String, line : Int32)
      super(description, file, line)
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
  end
end
