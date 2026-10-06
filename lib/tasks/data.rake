namespace :data do
  desc "Import the Olist dataset"
  task import_olist: :environment do
    path = Rails.root.join("data", "olist", "olist_customers_dataset.csv")
    count = 0
    CSV.foreach(path, headers: true) { |row| count += 1 }
    puts count
  end
end
