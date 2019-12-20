struct PicoTest
  class AssertionError < Exception
    getter :file
    getter :line

    def initialize(msg : String, @file : String = __FILE__, @line : Int32 = __LINE__)
      super(msg)
    end
  end
end
