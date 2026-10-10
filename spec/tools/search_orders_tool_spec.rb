require "rails_helper"

RSpec.describe SearchOrdersTool do
  it "is called search_orders by the model" do
    expect(described_class.new.name).to eq("search_orders")
  end

  it "requires a customer id and leaves the status optional" do
    schema = described_class.new.parameters_schema

    expect(schema["required"]).to eq([ "customer_id" ])
    expect(schema["properties"].keys).to contain_exactly("customer_id", "status")
  end

  it "passes the customer id and status on to SearchOrders" do
    order = create(:order, status: "shipped")
    create(:order, customer: order.customer, status: "delivered")

    result = described_class.new.call(customer_id: order.customer_id, status: "shipped")

    expect(result).to eq(SearchOrders.call(customer_id: order.customer_id, status: "shipped"))
    expect(result[:orders].size).to eq(1)
  end
end
