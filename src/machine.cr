require "./assert"

# :nodoc:
struct PicoTest
  private struct Machine
    enum State
      Init
      Before
      Run
      Next
      After
    end

    def initialize(@spec : PicoTest*, @state : State, @line : Int32)
      @last_line = 0
    end

    def run_validate_at(line : Int32)
      case {@state, @line}
      when {State::Run, .<=(line)}
        yield
      when {State::Init, _}
        @last_line = line
      end
      nil
    end

    # :nodoc:
    def move_next(@state : State)
    end

    # :nodoc:
    def move_next_at(@line : Int32)
      @state = State::Next
    end

    # :nodoc:
    def final_state?
      @state == State::After && @last_line <= @line
    end

    def before : Nil
      yield if @state.before?
    end

    def after : Nil
      yield if @state.after?
    end

    def describe_impl(description, file, line, end_line) : Nil
      @spec.value.describe_impl(description, file, line, end_line) do
        with itself yield
      end
    end

    macro describe(description, file = __FILE__, line = __LINE__, end_line = __END_LINE__)
      {% description = description.is_a?(StringLiteral) ? description : description.stringify %}
      next if run_validate_at({{ line }}) do
        describe_impl({{ description }}, {{ file }}, {{ line }}, {{ end_line }}) do
          {{ yield }}
        end
        move_next_at({{ end_line }})
        break true
      end
    end

    def it_impl(description, file, line, end_line) : Nil
      @spec.value.it_impl(description, file, line, end_line) do
        with PicoTest::Assert yield
      end
    end

    macro it(description, file = __FILE__, line = __LINE__, end_line = __END_LINE__)
      {% description = description.is_a?(StringLiteral) ? description : description.stringify %}
      next if run_validate_at({{ line }}) do
        it_impl({{ description }}, {{ file }}, {{ line }}, {{ end_line }}) do
          {{ yield }}
        end
        move_next_at({{ end_line }})
        break true
      end
    end

    def pending_impl(description, file, line, end_line)
      @spec.value.pending_impl(description, file, line, end_line)
    end

    macro pending(description, file = __FILE__, line = __LINE__, end_line = __END_LINE__)
      {% description = description.is_a?(StringLiteral) ? description : description.stringify %}
      next if run_validate_at({{ line }}) do
        pending_impl({{ description }}, {{ file }}, {{ line }}, {{ end_line }})
        move_next_at({{ end_line }})
        break true
      end
    end
  end
end
