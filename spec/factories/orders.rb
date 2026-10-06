FactoryBot.define do
  factory :order do
    olist_order_id { "MyString" }
    customer { nil }
    status { "MyString" }
    purchased_at { "2026-10-06 19:10:29" }
    approved_at { "2026-10-06 19:10:29" }
    shipped_at { "2026-10-06 19:10:29" }
    delivered_at { "2026-10-06 19:10:29" }
    estimated_delivery_at { "2026-10-06 19:10:29" }
  end
end
