namespace :data do
  desc "Import the Olist dataset"
  task import_olist: :environment do
    Faker::Config.random = Random.new(42)
    step = ->(message) { puts "#{Time.current.strftime("%H:%M:%S")}  #{message}" }

    OrderItem.delete_all
    Payment.delete_all
    Order.delete_all
    Product.delete_all
    Customer.delete_all

    step.call("importing customers")
    path = Rails.root.join("data", "olist", "olist_customers_dataset.csv")
    customers_by_unique_id = {}
    customers_by_olist_id = {}
    email_number = 0
    email_domains = %w[example.com example.org example.net]

    customer_rows = CSV.foreach(path, headers: true)
    customer_rows = customer_rows.first(ENV["LIMIT"].to_i) if ENV["LIMIT"]

    customer_rows.each do |row|
      customer = customers_by_unique_id[row["customer_unique_id"]]

      unless customer
        email_number += 1
        step.call("  #{email_number} customers created") if (email_number % 10_000).zero?
        name = Faker::Name.name
        email_domain = email_domains[email_number % email_domains.size]
        customer = Customer.create!(
          olist_customer_unique_id: row["customer_unique_id"],
          name: name,
          email: "#{name.parameterize(separator: ".")}.#{email_number}@#{email_domain}",
          city: row["customer_city"],
          state: row["customer_state"]
        )
        customers_by_unique_id[row["customer_unique_id"]] = customer
      end

      customers_by_olist_id[row["customer_id"]] = customer
    end

    step.call("customers: #{Customer.count}, lookup entries: #{customers_by_olist_id.size}")

    step.call("importing products")
    translations_path = Rails.root.join("data", "olist", "product_category_name_translation.csv")
    category_translations = {}

    CSV.foreach(translations_path, headers: true, encoding: "bom|utf-8") do |row|
      category_translations[row["product_category_name"]] = row["product_category_name_english"]
    end

    products_path = Rails.root.join("data", "olist", "olist_products_dataset.csv")

    product_rows = CSV.foreach(products_path, headers: true).map do |row|
      portuguese_category = row["product_category_name"]

      {
        olist_product_id: row["product_id"],
        name: Faker::Commerce.product_name,
        category: category_translations.fetch(portuguese_category, portuguese_category),
        name_length: row["product_name_lenght"],
        description_length: row["product_description_lenght"],
        photos_count: row["product_photos_qty"],
        weight_g: row["product_weight_g"],
        length_cm: row["product_length_cm"],
        height_cm: row["product_height_cm"],
        width_cm: row["product_width_cm"]
      }
    end

    product_rows.each_slice(1_000) { |batch| Product.insert_all(batch) }
    product_ids_by_olist_id = Product.pluck(:olist_product_id, :id).to_h

    step.call("products: #{Product.count}")

    step.call("importing orders")
    orders_path = Rails.root.join("data", "olist", "olist_orders_dataset.csv")
    orders_by_olist_id = {}
    skipped_orders = 0

    CSV.foreach(orders_path, headers: true) do |row|
      customer = customers_by_olist_id[row["customer_id"]]

      # With LIMIT only some customers exist, so their orders are the only ones we can keep
      unless customer
        skipped_orders += 1
        next
      end

      orders_by_olist_id[row["order_id"]] = Order.create!(
        olist_order_id: row["order_id"],
        customer: customer,
        status: row["order_status"],
        purchased_at: row["order_purchase_timestamp"],
        approved_at: row["order_approved_at"],
        shipped_at: row["order_delivered_carrier_date"],
        delivered_at: row["order_delivered_customer_date"],
        estimated_delivery_at: row["order_estimated_delivery_date"]
      )
    end

    step.call("orders: #{Order.count}, skipped: #{skipped_orders}")

    step.call("importing order items")
    order_items_path = Rails.root.join("data", "olist", "olist_order_items_dataset.csv")
    skipped_order_items = 0

    CSV.foreach(order_items_path, headers: true) do |row|
      order = orders_by_olist_id[row["order_id"]]

      unless order
        skipped_order_items += 1
        next
      end

      OrderItem.create!(
        order: order,
        product_id: product_ids_by_olist_id[row["product_id"]],
        price: row["price"],
        freight_value: row["freight_value"]
      )
    end

    step.call("order items: #{OrderItem.count}, skipped: #{skipped_order_items}")

    step.call("importing payments")
    payments_path = Rails.root.join("data", "olist", "olist_order_payments_dataset.csv")
    skipped_payments = 0

    CSV.foreach(payments_path, headers: true) do |row|
      order = orders_by_olist_id[row["order_id"]]

      unless order
        skipped_payments += 1
        next
      end

      Payment.create!(
        order: order,
        sequence: row["payment_sequential"],
        payment_method: row["payment_type"],
        installments: row["payment_installments"],
        amount: row["payment_value"]
      )
    end

    step.call("payments: #{Payment.count}, skipped: #{skipped_payments}")
  end
end
