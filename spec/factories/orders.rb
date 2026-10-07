FactoryBot.define do
  factory :order do
    customer
    sequence(:olist_order_id) { |n| "order-#{n}" }
    status { "delivered" }
    purchased_at { 30.days.ago }
    approved_at { 29.days.ago }
    shipped_at { 25.days.ago }
    delivered_at { 20.days.ago }
    estimated_delivery_at { 18.days.ago }
  end
end
