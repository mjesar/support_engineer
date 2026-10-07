class AddFinalSaleToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :final_sale, :boolean, null: false, default: false
  end
end
