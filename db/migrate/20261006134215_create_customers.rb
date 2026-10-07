class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :olist_customer_unique_id, null: false
      t.string :name
      t.string :email
      t.string :city
      t.string :state

      t.timestamps
    end
    add_index :customers, :olist_customer_unique_id, unique: true
  end
end
