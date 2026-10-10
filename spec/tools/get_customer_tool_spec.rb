require "rails_helper"

RSpec.describe GetCustomerTool do
  it "is called get_customer by the model" do
    expect(described_class.new.name).to eq("get_customer")
  end

  it "requires an integer customer id" do
    schema = described_class.new.parameters_schema

    expect(schema["required"]).to eq([ "customer_id" ])
    expect(schema["properties"]["customer_id"]["type"]).to eq("integer")
  end

  it "returns what GetCustomer returns" do
    customer = create(:customer)

    expect(described_class.new.call(customer_id: customer.id)).to eq(GetCustomer.call(customer.id))
  end
end
