require "rails_helper"

RSpec.describe NextStep do
  describe ".for" do
    it "looks up an order for order_status" do
      expect(described_class.for("order_status")).to eq(:look_up_order)
    end

    it "checks the refund policy for refund" do
      expect(described_class.for("refund")).to eq(:check_refund_policy)
    end

    it "escalates a complaint to a human" do
      expect(described_class.for("complaint")).to eq(:escalate_to_human)
    end

    it "answers directly for other" do
      expect(described_class.for("other")).to eq(:answer_directly)
    end

    it "raises on an intent the schema does not allow" do
      expect { described_class.for("banana") }.to raise_error(KeyError)
    end
  end
end
