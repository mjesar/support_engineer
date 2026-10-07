namespace :data do
  desc "Generate shipments from the imported orders"
  task generate_shipments: :environment do
    Faker::Config.random = Random.new(42)
    carriers = %w[Correios Jadlog Loggi Total\ Express]

    Shipment.delete_all

    # Orders that were never handed to a carrier (canceled, still processing) have no shipment
    Order.where.not(shipped_at: nil).find_in_batches(batch_size: 1_000) do |orders|
      rows = orders.map do |order|
        {
          order_id: order.id,
          carrier: carriers.sample(random: Faker::Config.random),
          tracking_number: Faker::Alphanumeric.alphanumeric(number: 12).upcase,
          status: order.delivered_at ? "delivered" : "in_transit",
          last_scan_at: order.delivered_at || order.shipped_at
        }
      end

      Shipment.insert_all(rows)
    end

    puts "shipments: #{Shipment.count}"
  end

  desc "Plant the scenarios the evals know the answer to"
  task plant_scenarios: :generate_shipments do
    # Orders with a shipment are picked by id order, so reruns always plant on the same orders
    candidates = Order.joins(:shipment).order(:id)

    delayed = candidates.first
    delayed.update!(status: "shipped", shipped_at: 13.days.ago, delivered_at: nil)
    delayed.shipment.update!(status: "in_transit", last_scan_at: 11.days.ago, last_known_location: "Curitiba hub")
    puts "delayed shipment: order #{delayed.id}"

    lost = candidates.offset(1).first
    lost.update!(status: "shipped", shipped_at: 21.days.ago, delivered_at: nil)
    lost.shipment.update!(status: "exception", last_scan_at: 16.days.ago, last_known_location: "Sao Paulo sorting center")
    puts "lost package: order #{lost.id}"

    expired_return = candidates.offset(2).first
    expired_return.update!(status: "delivered", shipped_at: 45.days.ago, delivered_at: 40.days.ago)
    expired_return.shipment.update!(status: "delivered", last_scan_at: 40.days.ago)
    puts "return window closed: order #{expired_return.id}"

    final_sale = candidates.offset(3).first
    final_sale.update!(status: "delivered", shipped_at: 8.days.ago, delivered_at: 5.days.ago)
    final_sale.shipment.update!(status: "delivered", last_scan_at: 5.days.ago)
    final_sale.products.first.update!(final_sale: true)
    puts "final sale item: order #{final_sale.id}"

    duplicate_charge = candidates.offset(4).first
    payment = duplicate_charge.payments.order(:sequence).first
    # find_or_create_by! keeps reruns from stacking extra duplicates
    duplicate_charge.payments.find_or_create_by!(
      sequence: payment.sequence + 1,
      payment_method: payment.payment_method,
      installments: payment.installments,
      amount: payment.amount
    )
    puts "duplicate charge: order #{duplicate_charge.id}"
  end
end
