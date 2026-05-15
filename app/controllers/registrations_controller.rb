class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    account = nil

    ActiveRecord::Base.transaction do
      @user.save!
      account = Account.create!(name: @user.name)
      AccountUser.create!(user: @user, account: account, role: "owner")
    end

    start_new_session_for(@user)
    session[:current_account_id] = account.id

    audit! "user.signup",     user: @user, account: account, auditable: @user
    audit! "account.created", user: @user, account: account, auditable: account

    redirect_to root_path, notice: I18n.t("flash.signup_succeeded")
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = I18n.t("flash.signup_failed")
    render :new, status: :unprocessable_entity
  end

  private
    def user_params
      params.expect(user: %i[name email_address password password_confirmation])
    end
end
