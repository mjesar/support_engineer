class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :sequence
      t.string :payment_method
      t.integer :installments
      t.decimal :amount, null: false, precision: 10, scale: 2

      t.timestamps
    end
  end
end
