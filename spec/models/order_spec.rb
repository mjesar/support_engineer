require "rails_helper"

RSpec.describe Order, type: :model do
  let(:order) { create(:order) }

  it "belongs to a customer" do
    expect(order.customer).to be_a(Customer)
  end

  it "reaches its products through order items" do
    item = create(:order_item, order: order)

    expect(order.products).to eq([ item.product ])
  end

  it "has many payments" do
    payment = create(:payment, order: order)

    expect(order.payments).to eq([ payment ])
  end

  it "has one shipment" do
    shipment = create(:shipment, order: order)

    expect(order.shipment).to eq(shipment)
  end

  it "removes its items, payments and shipment when destroyed" do
    create(:order_item, order: order)
    create(:payment, order: order)
    create(:shipment, order: order)

    expect { order.destroy }
      .to change { [ OrderItem.count, Payment.count, Shipment.count ] }.from([ 1, 1, 1 ]).to([ 0, 0, 0 ])
  end
end
