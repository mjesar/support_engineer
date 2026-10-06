namespace :data do
  desc "Import the Olist dataset"
  task import_olist: :environment do
    Faker::Config.random = Random.new(42)
    Customer.delete_all

    path = Rails.root.join("data", "olist", "olist_customers_dataset.csv")
    customers_by_unique_id = {}
    customers_by_olist_id = {}
    email_number = 0

    CSV.foreach(path, headers: true) do |row|
      customer = customers_by_unique_id[row["customer_unique_id"]]

      unless customer
        email_number += 1
        customer = Customer.create!(
          olist_customer_unique_id: row["customer_unique_id"],
          name: Faker::Name.name,
          email: "customer-#{email_number}@example.com",
          city: row["customer_city"],
          state: row["customer_state"]
        )
        customers_by_unique_id[row["customer_unique_id"]] = customer
      end

      customers_by_olist_id[row["customer_id"]] = customer
    end

    puts "customers: #{Customer.count}, lookup entries: #{customers_by_olist_id.size}"
  end
end
