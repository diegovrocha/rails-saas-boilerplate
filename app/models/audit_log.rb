class AuditLog < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :user,    optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true

  scope :recent,   -> { order(created_at: :desc) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :for_user,    ->(user_id) { where(user_id: user_id) }
  scope :with_action, ->(name) { where(action: name) }
end
