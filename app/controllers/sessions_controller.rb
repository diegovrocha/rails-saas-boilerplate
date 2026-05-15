class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      audit! "user.login", user: user
      redirect_to after_authentication_url, notice: I18n.t("flash.login_succeeded")
    else
      audit! "user.login_failed", user: nil, account: nil, email_address: params[:email_address].to_s
      redirect_to new_session_path, alert: I18n.t("flash.login_failed")
    end
  end

  def destroy
    user = Current.user
    terminate_session
    audit! "user.logout", user: user, account: nil
    redirect_to new_session_path, status: :see_other, notice: I18n.t("flash.logout_succeeded")
  end
end
