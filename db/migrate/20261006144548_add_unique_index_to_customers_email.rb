class AddUniqueIndexToCustomersEmail < ActiveRecord::Migration[8.1]
  def change
    add_index :customers, :email, unique: true
  end
end
