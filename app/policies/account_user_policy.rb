class AccountUserPolicy < ApplicationPolicy
  def index?   = membership?
  def create?  = admin?
  def update?  = admin?
  def destroy? = admin? && !last_owner?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.account
      scope.where(account_id: Current.account.id)
    end
  end

  private
    def last_owner?
      return false unless record.role_owner?
      record.account.account_users.where(role: "owner").count <= 1
    end
end
