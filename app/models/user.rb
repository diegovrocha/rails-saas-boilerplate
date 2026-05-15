class User < ApplicationRecord
  include Auditable

  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { minimum: 2, maximum: 120 }
  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def admin_of?(account)
    account_users.where(account: account, role: %w[owner admin]).exists?
  end

  def owner_of?(account)
    account_users.where(account: account, role: "owner").exists?
  end
end
