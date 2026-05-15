class Account < ApplicationRecord
  include Auditable

  CPF_FORMAT   = /\A\d{11}\z/
  PHONE_FORMAT = /\A\d{10,11}\z/

  BILLING_TYPES = { free: "free", credit_card: "credit_card" }.freeze

  enum :billing_type, BILLING_TYPES, prefix: :billing

  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users

  has_one :owner_relation, -> { where(role: "owner") }, class_name: "AccountUser", inverse_of: :account
  has_one :owner, through: :owner_relation, source: :user

  has_one :address, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true

  has_one :subscription, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 120 }
  validates :cpf,   format: { with: CPF_FORMAT },   allow_blank: true
  validates :phone, format: { with: PHONE_FORMAT }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :cpf, uniqueness: true, allow_blank: true

  scope :active, -> { where(active: true) }

  def admin_users
    users.joins(:account_users).where(account_users: { account_id: id, role: %w[owner admin] })
  end

  def member_users
    users.joins(:account_users).where(account_users: { account_id: id, role: "member" })
  end

  def sync_allowed? = active?

  def has_active_subscription? = subscription&.active? || false
  def subscription_status      = subscription&.status
  def current_plan             = subscription&.plan

  def start_checkout!(price_id: nil, success_url:, cancel_url:)
    price = price_id || Rails.application.credentials.dig(:stripe, :default_price_id)
    Billing::CreateCheckoutSession.call(
      account: self, price_id: price, success_url: success_url, cancel_url: cancel_url
    )
  end

  def open_billing_portal!(return_url:)
    Billing::CreatePortalSession.call(account: self, return_url: return_url)
  end
end
