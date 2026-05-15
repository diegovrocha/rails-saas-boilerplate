module Billing
  class PortalController < ApplicationController
    def create
      session = Current.account.open_billing_portal!(return_url: root_url)
      redirect_to session.url, allow_other_host: true, status: :see_other
    rescue Billing::CreatePortalSession::MissingCustomer
      redirect_to root_path, alert: I18n.t("flash.no_billing_yet", default: "Você ainda não possui assinatura ativa.")
    end
  end
end
