require "rails_helper"

RSpec.describe GetShipmentTool do
  it "is called get_shipment by the model" do
    expect(described_class.new.name).to eq("get_shipment")
  end

  it "requires an integer order id" do
    schema = described_class.new.parameters_schema

    expect(schema["required"]).to eq([ "order_id" ])
    expect(schema["properties"]["order_id"]["type"]).to eq("integer")
  end

  it "returns what GetShipment returns" do
    shipment = create(:shipment)

    expect(described_class.new.call(order_id: shipment.order_id)).to eq(GetShipment.call(shipment.order_id))
  end
end
