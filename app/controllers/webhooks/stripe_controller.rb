module Webhooks
  class StripeController < ActionController::API
    include RequestLogging

    rescue_from Stripe::SignatureVerificationError, with: :invalid_signature

    def create
      Current.request_id = request.request_id

      event = Stripe::Webhook.construct_event(
        request.body.read,
        request.headers["Stripe-Signature"],
        Rails.application.credentials.dig(:stripe, :webhook_secret)
      )

      Billing::StripeEventHandler.call(event)

      head :ok
    rescue Stripe::SignatureVerificationError
      raise
    rescue StandardError => e
      Rails.logger.error("[stripe-webhook] #{e.class}: #{e.message}")
      head :ok
    end

    private
      def invalid_signature
        head :bad_request
      end
  end
end
