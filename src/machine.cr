require "./assert"

# :nodoc:
struct PicoTest
  private struct Machine
    enum Phase
      Init
      Before
      Run
      After
    end

    def initialize(@spec : PicoTest*, @phase : Phase, @line : Int32)
      @last_line = 0
      @before_skippable = true
      @after_skippable = true
    end

    def run_validate_at(line : Int32)
      case {@phase, @line}
      when {Phase::Run, .<=(line)}
        yield
      when {Phase::Init, _}
        @last_line = line
      end
      nil
    end

    def next_phase! : Bool
      while true
        case @phase
        when Phase::Init
          @phase = Phase::Before

          next if @before_skippable
          return true
        when Phase::Before
          @phase = Phase::Run
          return true
        when Phase::Run
          @phase = Phase::After

          next if @after_skippable
          return true
        when Phase::After
          return false if @last_line <= @line

          @phase = Phase::Before

          next if @before_skippable
          return true
        end
      end
    end

    def next_line_state!(@line : Int32) : Bool
      !(@before_skippable && @after_skippable)
    end

    def before : Nil
      case @phase
      when Phase::Before
        yield
      when Phase::Init
        @before_skippable = false
      end
    end

    def after : Nil
      case @phase
      when Phase::After
        yield
      when Phase::Init
        @after_skippable = false
      end
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
        break next_line_state!({{ end_line }})
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
        break next_line_state!({{ end_line }})
      end
    end

    def pending_impl(description, file, line, end_line)
      @spec.value.pending_impl(description, file, line, end_line)
    end

    macro pending(description, file = __FILE__, line = __LINE__, end_line = __END_LINE__)
      {% description = description.is_a?(StringLiteral) ? description : description.stringify %}
      next if run_validate_at({{ line }}) do
        pending_impl({{ description }}, {{ file }}, {{ line }}, {{ end_line }})
        break next_line_state!({{ end_line }})
      end
    end
  end
end
