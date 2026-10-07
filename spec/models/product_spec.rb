require "rails_helper"

RSpec.describe Product, type: :model do
  it "is not a final sale item by default" do
    expect(create(:product).final_sale).to be(false)
  end

  it "reaches its orders through order items" do
    product = create(:product)
    order = create(:order)
    create(:order_item, order: order, product: product)

    expect(product.orders).to eq([ order ])
  end
end
