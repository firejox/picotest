require "./macros"
require "./machine"
require "./error"
require "./assert"

include PicoTest::Macros

struct PicoTest
  @@global_spec : PicoTest = new

  def self.spec
    with @@global_spec yield
  end

  protected def describe_impl(description : String, file, line, end_line) : Nil
    self_ptr = container_of(pointerof(@reporter), PicoTest, @reporter)
    machine = Machine.new(self_ptr, Machine::Phase::Init, line)

    @reporter.describe_scope(description, file, line) do
      with machine yield

      while machine.next_phase!
        with machine yield
      end
    end
  end

  macro describe(description, file = __FILE__, line = __LINE__, end_line = __END_LINE__)
    {% description = description.stringify %}
    describe_impl({{ description }}, {{ file }}, {{ line }}, {{ end_line }}) do
      {{ yield }}
    end
  end

  protected def it_impl(description : String, file, line, end_line) : Nil
    @reporter.it_scope(description, file, line) do
      with PicoTest::Assert yield
    end
  end

  macro it(description, file = __FILE__, line = __LINE__, end_line = __END_LINE__)
    {% description = description.stringify %}
    it_impl({{ description }}, {{ file }}, {{ line }}, {{ end_line }}) do
      {{ yield }}
    end
  end

  protected def pending_impl(description : String, file, line, end_line)
    @reporter.pending_scope(description.to_s, file, line)
  end

  macro pending(description, file = __FILE__, line = __LINE__, end_line = __END_LINE__, &block)
    {% description = description.stringify %}
    pending_impl({{ description }}, {{ file }}, {{ line }}, {{ end_line }})
  end

  at_exit do
    @@global_spec.@reporter.print_statistics_and_exit
  end
end
