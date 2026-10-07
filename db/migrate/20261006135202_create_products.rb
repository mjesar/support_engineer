class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :olist_product_id, null: false
      t.string :name
      t.string :category
      t.integer :name_length
      t.integer :description_length
      t.integer :photos_count
      t.integer :weight_g
      t.integer :length_cm
      t.integer :height_cm
      t.integer :width_cm

      t.timestamps
    end
    add_index :products, :olist_product_id, unique: true
  end
end
