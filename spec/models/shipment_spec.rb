require "rails_helper"

RSpec.describe Shipment, type: :model do
  it "belongs to an order" do
    expect(create(:shipment).order).to be_a(Order)
  end

  it "allows only one shipment per order" do
    order = create(:order)
    create(:shipment, order: order)

    expect { create(:shipment, order: order) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
