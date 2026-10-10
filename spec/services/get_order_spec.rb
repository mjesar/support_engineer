require "rails_helper"

RSpec.describe GetOrder do
  describe ".call" do
    let(:order) { create(:order, status: "shipped", delivered_at: nil) }

    before { create(:order_item, order: order, price: "59.90") }

    it "returns the order status and dates" do
      result = described_class.call(order.id)

      expect(result).to include(id: order.id, status: "shipped", delivered_at: nil)
      expect(result[:shipped_at]).to eq(order.shipped_at)
    end

    it "returns each item with name, category, price and final sale flag" do
      item = described_class.call(order.id)[:items].first

      expect(item).to eq(name: "Ergonomic Wooden Chair", category: "furniture_decor", price: 59.9, final_sale: false)
    end

    it "does not return fields the model does not need" do
      result = described_class.call(order.id)

      expect(result.keys).not_to include(:customer_id, :olist_order_id)
    end

    it "returns an error for an order that does not exist" do
      expect(described_class.call(0)).to eq(error: "Order 0 not found")
    end
  end
end
