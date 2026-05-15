class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string  :name, null: false
      t.string  :cpf
      t.string  :email
      t.string  :phone
      t.boolean :active, null: false, default: true
      t.string  :billing_type, null: false, default: "credit_card"

      t.timestamps
    end

    add_index :accounts, :cpf, unique: true, where: "cpf IS NOT NULL"
    add_index :accounts, :active
    add_index :accounts, :billing_type
  end
end
