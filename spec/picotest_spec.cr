require "./spec_helper"

PicoTest.spec do
  describe "example spec" do
    it "assert true == true" do
      assert true == true
    end

    it "reject true == false" do
      reject true == false
    end

    it "catch raise" do
      assert_raise(Exception) do
        raise "OH NO!"
      end
    end

    it "no raise in block" do
      reject_raise do
        "it is safe"
      end
    end

    pending "pending test"

    pending "pending with block" do
    end
  end
end
