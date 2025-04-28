class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.string :title
      t.decimal :price
      t.string :file_url
      t.string :description
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
