namespace :data do
  desc "Import the Olist dataset"
  task import_olist: :environment do
    Faker::Config.random = Random.new(42)
    Product.delete_all
    Customer.delete_all

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

    puts "customers: #{Customer.count}, lookup entries: #{customers_by_olist_id.size}"

    translations_path = Rails.root.join("data", "olist", "product_category_name_translation.csv")
    category_translations = {}

    CSV.foreach(translations_path, headers: true, encoding: "bom|utf-8") do |row|
      category_translations[row["product_category_name"]] = row["product_category_name_english"]
    end

    products_path = Rails.root.join("data", "olist", "olist_products_dataset.csv")
    products_by_olist_id = {}

    CSV.foreach(products_path, headers: true) do |row|
      portuguese_category = row["product_category_name"]

      products_by_olist_id[row["product_id"]] = Product.create!(
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
      )
    end

    puts "products: #{Product.count}"
  end
end
