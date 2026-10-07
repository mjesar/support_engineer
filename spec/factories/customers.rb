FactoryBot.define do
  factory :customer do
    sequence(:olist_customer_unique_id) { |n| "unique-customer-#{n}" }
    sequence(:email) { |n| "customer#{n}@example.com" }
    name { "Ana Silva" }
    city { "curitiba" }
    state { "PR" }
  end
end
