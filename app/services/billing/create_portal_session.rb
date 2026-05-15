module Billing
  class CreatePortalSession
    class MissingCustomer < StandardError; end

    def self.call(**kwargs) = new(**kwargs).call

    def initialize(account:, return_url:)
      @account    = account
      @return_url = return_url
    end

    def call
      customer = @account.subscription&.stripe_customer_id
      raise MissingCustomer, "Account #{@account.id} has no Stripe customer yet" if customer.blank?

      Stripe::BillingPortal::Session.create(customer: customer, return_url: @return_url)
    end
  end
end
