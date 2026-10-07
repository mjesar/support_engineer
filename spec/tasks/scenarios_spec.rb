require "rails_helper"
require "rake"

RSpec.describe "data:plant_scenarios" do
  let!(:orders) do
    create_list(:order, 5).each do |order|
      create(:order_item, order: order)
      create(:payment, order: order)
    end
  end

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("data:plant_scenarios")
    allow($stdout).to receive(:puts)
  end

  def plant_scenarios
    %w[data:generate_shipments data:plant_scenarios].each { |name| Rake::Task[name].reenable }
    Rake::Task["data:plant_scenarios"].invoke
  end

  it "creates a shipment for every order that was shipped" do
    plant_scenarios

    expect(Shipment.count).to eq(5)
  end

  it "plants a delayed shipment: in transit for more than 12 days" do
    plant_scenarios
    delayed = orders[0].reload

    expect(delayed.shipped_at).to be < 12.days.ago
    expect(delayed.delivered_at).to be_nil
    expect(delayed.shipment.status).to eq("in_transit")
  end

  it "plants a lost package: carrier status exception" do
    plant_scenarios

    expect(orders[1].reload.shipment.status).to eq("exception")
  end

  it "plants a closed return window: delivered more than 30 days ago" do
    plant_scenarios
    expired = orders[2].reload

    expect(expired.status).to eq("delivered")
    expect(expired.delivered_at).to be < 30.days.ago
  end

  it "plants a final sale item inside the return window" do
    plant_scenarios
    final_sale = orders[3].reload

    expect(final_sale.delivered_at).to be > 30.days.ago
    expect(final_sale.products.first.final_sale).to be(true)
  end

  it "plants a duplicate charge: two identical payments" do
    plant_scenarios
    first, second = orders[4].payments.order(:sequence)

    expect(second.amount).to eq(first.amount)
    expect(second.payment_method).to eq(first.payment_method)
  end

  it "does not stack another duplicate when run twice" do
    plant_scenarios
    plant_scenarios

    expect(orders[4].payments.count).to eq(2)
  end
end
