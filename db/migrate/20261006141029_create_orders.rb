class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :olist_order_id, null: false
      t.references :customer, null: false, foreign_key: true
      t.string :status, null: false
      t.datetime :purchased_at
      t.datetime :approved_at
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.datetime :estimated_delivery_at

      t.timestamps
    end
    add_index :orders, :olist_order_id, unique: true
  end
end
