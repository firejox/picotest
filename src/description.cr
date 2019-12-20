require "./list"

struct PicoTest
  struct Description
    getter :dsl_type
    getter :description
    getter :file
    getter :line
    getter :link

    def initialize(@dsl_type : Symbol, @description : String, @file : String = __FILE__, @line : Int32 = __LINE__)
      @link = List::Node.new
    end
  end
end
