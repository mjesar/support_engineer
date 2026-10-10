require "rails_helper"

RSpec.describe GetOrderTool do
  it "is called get_order by the model" do
    expect(described_class.new.name).to eq("get_order")
  end

  it "requires an integer order id" do
    schema = described_class.new.parameters_schema

    expect(schema["required"]).to eq([ "order_id" ])
    expect(schema["properties"]["order_id"]["type"]).to eq("integer")
  end

  it "returns what GetOrder returns" do
    order = create(:order)

    expect(described_class.new.call(order_id: order.id)).to eq(GetOrder.call(order.id))
  end
end
