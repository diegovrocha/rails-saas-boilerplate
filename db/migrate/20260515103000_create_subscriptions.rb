class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string  :stripe_customer_id
      t.string  :stripe_subscription_id, null: false
      t.string  :stripe_price_id
      t.string  :plan
      t.string  :status, null: false
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, null: false, default: false
      t.datetime :trial_ends_at
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :subscriptions, :stripe_customer_id
    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, :status
  end
end
