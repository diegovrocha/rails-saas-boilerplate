class Subscription < ApplicationRecord
  include Auditable

  belongs_to :account

  STATUSES = %w[active trialing past_due canceled incomplete incomplete_expired unpaid paused].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :stripe_subscription_id, presence: true, uniqueness: true

  scope :active_status, -> { where(status: %w[active trialing]) }

  def active?
    %w[active trialing].include?(status)
  end

  def in_trial?
    status == "trialing" && trial_ends_at&.future?
  end

  def expired?
    current_period_end&.past? && !cancel_at_period_end?
  end
end
