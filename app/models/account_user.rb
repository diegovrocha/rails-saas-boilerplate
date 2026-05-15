class AccountUser < ApplicationRecord
  ROLES = { owner: "owner", admin: "admin", member: "member" }.freeze

  enum :role, ROLES, prefix: :role

  belongs_to :account
  belongs_to :user

  validates :user_id, uniqueness: { scope: :account_id }
end
