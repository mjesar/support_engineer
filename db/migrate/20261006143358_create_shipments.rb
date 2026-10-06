class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.string :carrier
      t.string :tracking_number
      t.string :status, null: false
      t.string :last_known_location
      t.datetime :last_scan_at

      t.timestamps
    end
  end
end
