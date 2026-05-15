class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :zip
      t.string :street
      t.string :number
      t.string :complement
      t.string :neighborhood
      t.string :city
      t.string :state
      t.string :country, default: "BR"

      t.timestamps
    end
  end
end
