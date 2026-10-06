# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_06_135202) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "olist_customer_unique_id", null: false
    t.string "name"
    t.string "email"
    t.string "city"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["olist_customer_unique_id"], name: "index_customers_on_olist_customer_unique_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "olist_product_id", null: false
    t.string "name"
    t.string "category"
    t.integer "name_length"
    t.integer "description_length"
    t.integer "photos_count"
    t.integer "weight_g"
    t.integer "length_cm"
    t.integer "height_cm"
    t.integer "width_cm"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["olist_product_id"], name: "index_products_on_olist_product_id", unique: true
  end
end
