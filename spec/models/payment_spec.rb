require "rails_helper"

RSpec.describe Payment, type: :model do
  it "belongs to an order" do
    expect(create(:payment).order).to be_a(Order)
  end
end
