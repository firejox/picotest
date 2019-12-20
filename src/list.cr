# :nodoc:
struct PicoTest
  private struct List
    struct Node
      property previous : Pointer(self) = Pointer(self).null
      property next : Pointer(self) = Pointer(self).null

      @[AlwaysInline]
      protected def self.link(p : Pointer(self), q : Pointer(self))
        p.value.next = q
        q.value.previous = p
      end

      @[AlwaysInline]
      protected def self.insert(x : Pointer(self), p : Pointer(self), q : Pointer(self))
        p.value.next = x
        x.value.previous = p
        x.value.next = q
        q.value.previous = x
      end

      def init
        @previous = @next = self.self_pointer
      end

      def unlink
        typeof(self).link @previous, @next
      end

      def self_pointer
        (->self.itself).closure_data.as(Pointer(self))
      end
    end

    @head = Node.new

    def init
      @head.init
    end

    def first
      @head.next
    end

    def empty?
      @head.next == pointerof(@head)
    end

    def unshift(node : Pointer(Node))
      Node.insert(node, pointerof(@head), @head.next)
    end

    def delete(node : Pointer(Node))
      node.value.unlink
    end

    def shift
      unless empty?
        first.tap { |node| delete(node) }
      else
        yield
      end
    end

    def shift
      shift { raise "Empty error" }
    end

    def each
      it = @head.next
      while it != pointerof(@head)
        yield it
        it = it.value.next
      end
    end
  end
end
