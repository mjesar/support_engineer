require "rails_helper"

RSpec.describe GetShipment do
  describe ".call" do
    let(:order) { create(:order) }

    it "returns the shipment status, carrier, tracking number and last scan" do
      shipment = create(:shipment, order: order, last_known_location: "Sao Paulo")

      result = described_class.call(order.id)

      expect(result).to eq(
        status: "in_transit",
        carrier: "Correios",
        tracking_number: shipment.tracking_number,
        last_known_location: "Sao Paulo",
        last_scan_at: shipment.last_scan_at
      )
    end

    it "does not return ids or timestamps the model does not need" do
      create(:shipment, order: order)

      result = described_class.call(order.id)

      expect(result.keys).not_to include(:id, :order_id, :created_at, :updated_at)
    end

    it "returns an error for an order that does not exist" do
      expect(described_class.call(0)).to eq(error: "Order 0 not found")
    end

    it "returns an error for an order that has no shipment yet" do
      expect(described_class.call(order.id)).to eq(error: "Order #{order.id} has no shipment")
    end
  end
end
