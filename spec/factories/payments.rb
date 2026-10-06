FactoryBot.define do
  factory :payment do
    order { nil }
    sequence { 1 }
    payment_method { "MyString" }
    installments { 1 }
    amount { "9.99" }
  end
end
