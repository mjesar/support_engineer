FactoryBot.define do
  factory :product do
    sequence(:olist_product_id) { |n| "product-#{n}" }
    name { "Ergonomic Wooden Chair" }
    category { "furniture_decor" }
  end
end
