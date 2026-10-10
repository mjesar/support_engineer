require "rails_helper"

RSpec.describe GetCustomer do
  describe ".call" do
    it "returns the customer name and location" do
      customer = create(:customer, name: "Ana Silva", city: "curitiba", state: "PR")

      expect(described_class.call(customer.id)).to eq(id: customer.id, name: "Ana Silva", city: "curitiba", state: "PR")
    end

    it "does not return the email or the Olist id" do
      customer = create(:customer)

      result = described_class.call(customer.id)

      expect(result.keys).not_to include(:email, :olist_customer_unique_id)
    end

    it "returns an error for a customer that does not exist" do
      expect(described_class.call(0)).to eq(error: "Customer 0 not found")
    end
  end
end
