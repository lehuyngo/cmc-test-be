class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.decimal :amount,       precision: 10, scale: 2 ,null: false
      t.references :customer, null: false, foreign_key: { to_table: :users }
      t.references :asset, null: false, foreign_key: true

      t.timestamps
    end
  end
end
