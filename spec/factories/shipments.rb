FactoryBot.define do
  factory :shipment do
    order
    carrier { "Correios" }
    sequence(:tracking_number) { |n| "TRACK#{n.to_s.rjust(7, "0")}" }
    status { "in_transit" }
    last_scan_at { 2.days.ago }
  end
end
