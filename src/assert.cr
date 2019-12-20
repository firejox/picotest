require "./error"

struct PicoTest::Assert
  private def self.assert_impl(failed_message, file = __FILE__, line = __LINE__)
    unless (yield)
      raise PicoTest::AssertionError.new(failed_message, file, line)
    end
  end

  private def self.reject_impl(failed_message, file = __FILE__, line = __LINE__)
    if (yield)
      raise PicoTest::AssertionError.new(failed_message, file, line)
    end
  end

  macro assert(expression, file = __FILE__, line = __LINE__)
    {% message = "Assertion failed: the evaluation of `#{expression}` should be true." %}
    assert_impl({{ message }}, {{ file }}, {{ line }}) do
      {{ expression }}
    end
  end

  macro reject(expression, file = __FILE__, line = __LINE__)
    {% message = "Assertion failed: the evaluation of `#{expression}` should be false." %}
    reject_impl({{ message }}, {{ file }}, {{ line }}) do
      {{ expression }}
    end
  end

  macro assert_raise(klass = Exception, file = __FILE__, line = __LINE__)
    begin
      {{ yield }}
    rescue %ex : {{ klass }}
    rescue %ex
      assert_impl("Assertion failed: caught unexpected exception #{%ex}", {{ file }}, {{ line }}) do
        %ex.is_a?({{ klass }})
      end
    else
      raise PicoTest::AssertionError.new("Assertion failed: no exception is raised.", {{ file }}, {{ line }})
    end
  end

  macro reject_raise(file = __FILE__, line = __LINE__)
    begin
      {{ yield }}
    rescue %ex
      raise PicoTest::AssertionError.new("Assertion failed: caught exception #{%ex}", {{ file }}, {{ line }})
    end
  end
end
