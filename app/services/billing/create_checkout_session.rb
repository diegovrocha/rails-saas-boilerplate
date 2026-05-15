module Billing
  class CreateCheckoutSession
    def self.call(**kwargs) = new(**kwargs).call

    def initialize(account:, price_id:, success_url:, cancel_url:)
      @account     = account
      @price_id    = price_id
      @success_url = success_url
      @cancel_url  = cancel_url
    end

    def call
      Stripe::Checkout::Session.create(
        mode: "subscription",
        line_items: [ { price: @price_id, quantity: 1 } ],
        customer: existing_customer_id,
        customer_email: existing_customer_id.nil? ? @account.email.presence || @account.owner&.email_address : nil,
        client_reference_id: @account.id.to_s,
        success_url: @success_url,
        cancel_url: @cancel_url,
        metadata: { account_id: @account.id.to_s }
      )
    end

    private
      def existing_customer_id
        @account.subscription&.stripe_customer_id
      end
  end
end
