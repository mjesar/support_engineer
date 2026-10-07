FactoryBot.define do
  factory :payment do
    order
    add_attribute(:sequence) { 1 }
    payment_method { "credit_card" }
    installments { 1 }
    amount { "59.90" }
  end
end
