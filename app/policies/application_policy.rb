class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  def index?  = membership?
  def show?   = membership?
  def create? = admin?
  def new?    = create?
  def update? = admin?
  def edit?   = update?
  def destroy? = admin?

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      return scope.none unless Current.account
      return scope.all unless scope.column_names.include?("account_id")

      scope.where(account_id: Current.account.id)
    end
  end

  private
    def membership?
      return false unless user && Current.account
      user.account_users.where(account_id: Current.account.id).exists?
    end

    def admin?
      return false unless user && Current.account
      user.admin_of?(Current.account)
    end

    def owner?
      return false unless user && Current.account
      user.owner_of?(Current.account)
    end
end
