require "./reporter"
require "./dsl"

struct PicoTest
  VERSION = "0.1.0"

  private def initialize
    @reporter = PicoTest::Reporter.new(STDERR)
  end
end
