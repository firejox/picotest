require "./spec_helper"

PicoTest.spec do
  x = 0
  y = 0
  describe "Hook spec" do
    before do
      x += 1
    end

    after do
      y += 1
    end

    it "test case 1" do
      assert x == 1
      assert y == 0
    end

    describe "inner spec" do
      before do
        x += 2
      end

      after do
        y += 2
      end

      it "test case 3" do
        assert x == 4
        assert y == 1
      end

      it "test case 4" do
        assert x == 6
        assert y == 3
      end
    end

    it "test case 2" do
      assert x == 7
      assert y == 6
    end
  end
end
