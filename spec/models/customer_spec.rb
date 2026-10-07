require "rails_helper"

RSpec.describe Customer, type: :model do
  it "has many orders" do
    customer = create(:customer)
    order = create(:order, customer: customer)

    expect(customer.orders).to eq([ order ])
  end

  it "does not allow two customers with the same email" do
    create(:customer, email: "ana@example.com")

    expect { create(:customer, email: "ana@example.com") }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
