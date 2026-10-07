FactoryBot.define do
  factory :order_item do
    order
    product
    price { "59.90" }
    freight_value { "12.50" }
  end
end
