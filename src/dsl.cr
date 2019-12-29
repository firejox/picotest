require "./machine"
require "./error"
require "./assert"
require "./spec"

struct PicoTest
  @@runner = Spec::Runner.new STDOUT

  struct Spec
    # :nodoc:
    def describe_impl(description : String, file, line, end_line) : Nil
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

  # :nodoc:
  def self.global_runner
    with @@runner yield
  end

  # :nodoc:
  def self.spec_impl(sync = true)
    @@runner.spec(sync) do
      with itself yield
    end
  end

  macro spec(sync = true, same_thread = false, &block)
    {% if block && block.body %}
      {% if sync %}
        PicoTest.spec_impl do
          {{ block.body }}
        end
      {% else %}
        PicoTest.global_runner do
          async_spec_start
          spawn(same_thread: {{ same_thread }}) do
            PicoTest.spec_impl(sync: false) do
              {{ block.body }}
            end
          end
        end
      {% end %}
    {% end %}
  end

  at_exit do
    global_runner do
      print_statistics
      abort unless succeeded?
    end
  end
end
