FactoryBot.define do
  factory :order_item do
    order { nil }
    product { nil }
    price { "9.99" }
    freight_value { "9.99" }
  end
end
