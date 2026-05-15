class AccountUsersController < ApplicationController
  before_action :require_current_account
  before_action :set_account_user, only: %i[update destroy]

  def index
    @account_users = policy_scope(AccountUser).includes(:user).order(:role)
    @new_account_user = AccountUser.new
  end

  def create
    authorize AccountUser.new(account: Current.account)
    user = User.find_by(email_address: params.dig(:account_user, :email_address).to_s.strip.downcase)

    if user.nil?
      flash[:alert] = I18n.t("flash.member_invite_failed")
      redirect_to account_users_path and return
    end

    @account_user = AccountUser.new(account: Current.account, user: user, role: params.dig(:account_user, :role).presence || "member")

    if @account_user.save
      audit! "account_user.added", auditable: @account_user, role: @account_user.role
      redirect_to account_users_path, notice: I18n.t("flash.member_invited")
    else
      flash[:alert] = I18n.t("flash.member_invite_failed")
      redirect_to account_users_path
    end
  end

  def update
    authorize @account_user
    previous_role = @account_user.role

    if @account_user.update(account_user_params)
      audit! "account_user.role_changed", auditable: @account_user, from: previous_role, to: @account_user.role
      redirect_to account_users_path, notice: I18n.t("flash.member_updated")
    else
      redirect_to account_users_path, alert: I18n.t("flash.member_invite_failed")
    end
  end

  def destroy
    authorize @account_user
    member_user_id = @account_user.user_id
    role = @account_user.role

    if @account_user.destroy
      audit! "account_user.removed", auditable: @account_user, member_user_id: member_user_id, role: role
      redirect_to account_users_path, notice: I18n.t("flash.member_removed")
    else
      redirect_to account_users_path, alert: I18n.t("flash.last_owner_protected")
    end
  end

  private
    def set_account_user
      @account_user = policy_scope(AccountUser).find(params[:id])
    end

    def account_user_params
      params.expect(account_user: [ :role ])
    end

    def require_current_account
      redirect_to root_path, alert: I18n.t("flash.not_authorized") unless Current.account
    end
end
