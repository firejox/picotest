require "./spec_helper"

PicoTest.spec(sync: false) do
  describe "example async spec" do
    it "run asynchronously" do
      elapse = Time.measure do
        sleep 5
      end

      assert elapse >= 5.seconds
    end
  end
end

PicoTest.spec sync: false do
  describe "example async spec2" do
    it "run asynchronously" do
      elapse = Time.measure do
        sleep 3
      end

      assert elapse >= 3.seconds
    end
  end
end
