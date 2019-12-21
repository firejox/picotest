struct PicoTest
  class UnhandledError < Exception
    getter :file
    getter :line

    def initialize(ex : Exception, @file : String, @line : Int32)
      super(cause: ex)
    end

    def description
      "Unhandled Exception caught: #{cause}"
    end
  end

  class AssertionError < Exception
    getter :file
    getter :line

    def initialize(msg : String, @file : String, @line : Int32)
      super(msg)
    end

    def description
      message
    end
  end
end
