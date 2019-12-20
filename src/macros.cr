# :nodoc:
struct PicoTest
  module Macros
    macro included
      private macro container_of(ptr, type, member)
        {% verbatim do %}
          {% ptype = type.is_a?(Generic) ? type.name.resolve : type.resolve %}
          {% if ptype <= Reference %}
            (({{ ptr }}).as(Pointer(Void)) - offsetof({{ type }}, {{ member }})).as({{ type }})
          {% else %}
            (({{ ptr }}).as(Pointer(Void)) - offsetof({{ type }}, {{ member }})).as(Pointer({{ type }}))
          {% end %}
        {% end %}
      end
    end
  end
end
