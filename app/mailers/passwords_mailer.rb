class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: I18n.t("mailers.passwords.subject"), to: user.email_address
  end
end
