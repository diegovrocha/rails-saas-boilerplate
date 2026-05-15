class AccountPolicy < ApplicationPolicy
  def show?    = membership?
  def update?  = admin?
  def destroy? = owner?
  def switch?  = membership?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user
      scope.joins(:account_users).where(account_users: { user_id: user.id })
    end
  end
end
