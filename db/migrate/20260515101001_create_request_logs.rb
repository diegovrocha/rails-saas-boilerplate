class CreateRequestLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :request_logs do |t|
      t.references :account, null: true, foreign_key: true
      t.references :user,    null: true, foreign_key: true
      t.string  :request_id
      t.string  :method
      t.string  :path
      t.integer :status
      t.integer :duration_ms
      t.string  :category
      t.json    :params, null: false, default: {}
      t.string  :ip
      t.string  :user_agent
      t.datetime :created_at, null: false
    end

    add_index :request_logs, :request_id
    add_index :request_logs, :status
    add_index :request_logs, :duration_ms
    add_index :request_logs, :category
    add_index :request_logs, :created_at
  end
end
