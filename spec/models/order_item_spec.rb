require "rails_helper"

RSpec.describe OrderItem, type: :model do
  it "belongs to an order and a product" do
    item = create(:order_item)

    expect(item.order).to be_a(Order)
    expect(item.product).to be_a(Product)
  end
end
