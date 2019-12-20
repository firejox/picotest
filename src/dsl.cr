require "./description"
require "./error"
require "./assert"

struct PicoTest
  @@global_spec : PicoTest = new
  @@global_spec.@reporter.init_stack

  def self.spec
    with @@global_spec yield
  end

  protected def describe_impl(description : String, file = __FILE__, line = __LINE__)
    @reporter.describe_scope(description, file, line) do
      with self yield
    end
  end

  macro describe(description, file = __FILE__, line = __LINE__)
    {% description = description.is_a?(StringLiteral) ? description : description.stringify %}
    describe_impl({{ description }}, {{ file }}, {{ line }}) do
      {{ yield }}
    end
  end

  protected def it_impl(description : String, file = __FILE__, line = __LINE__)
    @reporter.it_scope(description, file, line) do
      with PicoTest::Assert yield
    end
  end

  macro it(description, file = __FILE__, line = __LINE__)
    {% description = description.is_a?(StringLiteral) ? description : description.stringify %}
    it_impl({{ description }}, {{ file }}, {{ line }}) do
      {{ yield }}
    end
  end

  protected def pending_impl(description : String, file = __FILE__, line = __LINE__)
    @reporter.pending_scope(description.to_s, file, line)
  end

  macro pending(description, file = __FILE__, line = __LINE__, &block)
    {% description = description.is_a?(StringLiteral) ? description : description.stringify %}
    pending_impl({{ description }}, {{ file }}, {{ line }})
  end

  at_exit do
    @@global_spec.@reporter.print_statistics_and_exit
  end
end
