class RequestLog < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :user,    optional: true

  CATEGORIES = %w[sync webhook auth payment notification admin api].freeze

  scope :recent,        -> { order(created_at: :desc) }
  scope :for_account,   ->(account_id) { where(account_id: account_id) }
  scope :for_user,      ->(user_id) { where(user_id: user_id) }
  scope :errors_only,   -> { where("status >= ?", 400) }
  scope :slow,          ->(ms = 1000) { where("duration_ms >= ?", ms) }
  scope :in_period,     ->(period) { where("created_at >= ?", period_ago(period)) }
  scope :by_category,   ->(cat) { where(category: cat) }
  scope :starting_from, ->(date) { where("created_at >= ?", date) }
  scope :ending_at,     ->(date) { where("created_at <= ?", date) }

  def self.period_ago(period)
    case period.to_s
    when "1h"  then 1.hour.ago
    when "24h" then 24.hours.ago
    when "7d"  then 7.days.ago
    when "30d" then 30.days.ago
    when "60d" then 60.days.ago
    else 24.hours.ago
    end
  end

  def error? = status.to_i >= 400
  def slow?  = duration_ms.to_i >= 1000
end
