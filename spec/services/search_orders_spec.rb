require "rails_helper"

RSpec.describe SearchOrders do
  describe ".call" do
    let(:customer) { create(:customer) }

    it "returns a summary of the customer's orders, newest first" do
      older = create(:order, customer: customer, purchased_at: 10.days.ago)
      newer = create(:order, customer: customer, purchased_at: 2.days.ago)

      result = described_class.call(customer_id: customer.id)

      expect(result[:total]).to eq(2)
      expect(result[:orders].map { |order| order[:id] }).to eq([ newer.id, older.id ])
    end

    it "returns only the fields of a summary" do
      create(:order, customer: customer, status: "shipped")

      order = described_class.call(customer_id: customer.id)[:orders].first

      expect(order.keys).to contain_exactly(:id, :status, :purchased_at, :estimated_delivery_at)
    end

    it "filters by status" do
      create(:order, customer: customer, status: "delivered")
      shipped = create(:order, customer: customer, status: "shipped")

      result = described_class.call(customer_id: customer.id, status: "shipped")

      expect(result[:orders].map { |order| order[:id] }).to eq([ shipped.id ])
    end

    it "does not return orders of other customers" do
      create(:order)

      expect(described_class.call(customer_id: customer.id)).to eq(total: 0, orders: [])
    end

    it "returns at most the limit but reports the real total" do
      create_list(:order, described_class::LIMIT + 2, customer: customer)

      result = described_class.call(customer_id: customer.id)

      expect(result[:orders].size).to eq(described_class::LIMIT)
      expect(result[:total]).to eq(described_class::LIMIT + 2)
    end

    it "returns an error for a customer that does not exist" do
      expect(described_class.call(customer_id: 0)).to eq(error: "Customer 0 not found")
    end
  end
end
