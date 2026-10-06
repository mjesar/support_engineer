FactoryBot.define do
  factory :shipment do
    order { nil }
    carrier { "MyString" }
    tracking_number { "MyString" }
    status { "MyString" }
    last_known_location { "MyString" }
    last_scan_at { "2026-10-06 19:33:58" }
  end
end
