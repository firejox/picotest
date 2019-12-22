require "./macros"
require "./machine"
require "./error"
require "./assert"
require "./spec"

include PicoTest::Macros

struct PicoTest
  struct Spec
    protected def describe_impl(description : String, file, line, end_line) : Nil
      describe_internal(description, file, line) do
        machine = Machine.new(self.self_pointer, Machine::Phase::Init, line)
        with machine yield

        while machine.next_phase!
          with machine yield
        end
      end
    end

    protected def it_impl(description : String, file, line, end_line) : Nil
      it_internal(description, file, line) do
        with PicoTest::Assert yield
      end
    end

    protected def pending_impl(description : String, file, line, end_line) : Nil
      pending_internal(description, file, line)
    end

    macro describe(description, file = __FILE__, line = __LINE__, end_line = __END_LINE__)
      {% description = description.stringify %}
      describe_impl({{ description }}, {{ file }}, {{ line }}, {{ end_line }}) do
        {{ yield }}
      end
    end
  end

  def self.spec
    Spec::Runner.global_runner do
      spec = new_spec
      with spec yield
      report pointerof(spec)
    end
  end
end
