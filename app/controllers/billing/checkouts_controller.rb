module Billing
  class CheckoutsController < ApplicationController
    def create
      session = Current.account.start_checkout!(
        price_id:    params[:price_id].presence,
        success_url: success_billing_checkout_url,
        cancel_url:  cancel_billing_checkout_url
      )

      redirect_to session.url, allow_other_host: true, status: :see_other
    end

    def success
      redirect_to root_path, notice: I18n.t("flash.checkout_success", default: "Pagamento confirmado.")
    end

    def cancel
      redirect_to root_path, alert: I18n.t("flash.checkout_canceled", default: "Pagamento cancelado.")
    end
  end
end
