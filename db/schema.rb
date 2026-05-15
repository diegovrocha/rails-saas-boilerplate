# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_15_103001) do
  create_table "account_users", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["role"], name: "index_account_users_on_role"
    t.index ["user_id", "account_id"], name: "index_account_users_on_user_id_and_account_id", unique: true
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "billing_type", default: "credit_card", null: false
    t.string "cpf"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_accounts_on_active"
    t.index ["billing_type"], name: "index_accounts_on_billing_type"
    t.index ["cpf"], name: "index_accounts_on_cpf", unique: true, where: "cpf IS NOT NULL"
  end

  create_table "addresses", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "city"
    t.string "complement"
    t.string "country", default: "BR"
    t.datetime "created_at", null: false
    t.string "neighborhood"
    t.string "number"
    t.string "state"
    t.string "street"
    t.datetime "updated_at", null: false
    t.string "zip"
    t.index ["account_id"], name: "index_addresses_on_account_id", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.integer "account_id"
    t.string "action", null: false
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "ip"
    t.json "metadata", default: {}, null: false
    t.string "user_agent"
    t.integer "user_id"
    t.index ["account_id"], name: "index_audit_logs_on_account_id"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "processed_stripe_events", force: :cascade do |t|
    t.string "event_type", null: false
    t.datetime "processed_at", null: false
    t.string "stripe_event_id", null: false
    t.index ["stripe_event_id"], name: "index_processed_stripe_events_on_stripe_event_id", unique: true
  end

  create_table "request_logs", force: :cascade do |t|
    t.integer "account_id"
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.string "ip"
    t.string "method"
    t.json "params", default: {}, null: false
    t.string "path"
    t.string "request_id"
    t.integer "status"
    t.string "user_agent"
    t.integer "user_id"
    t.index ["account_id"], name: "index_request_logs_on_account_id"
    t.index ["category"], name: "index_request_logs_on_category"
    t.index ["created_at"], name: "index_request_logs_on_created_at"
    t.index ["duration_ms"], name: "index_request_logs_on_duration_ms"
    t.index ["request_id"], name: "index_request_logs_on_request_id"
    t.index ["status"], name: "index_request_logs_on_status"
    t.index ["user_id"], name: "index_request_logs_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.json "metadata", default: {}, null: false
    t.string "plan"
    t.string "status", null: false
    t.string "stripe_customer_id"
    t.string "stripe_price_id"
    t.string "stripe_subscription_id", null: false
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id", unique: true
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_customer_id"], name: "index_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "account_users", "accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "addresses", "accounts"
  add_foreign_key "audit_logs", "accounts"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "request_logs", "accounts"
  add_foreign_key "request_logs", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscriptions", "accounts"
end
