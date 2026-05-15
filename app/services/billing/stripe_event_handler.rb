module Billing
  class StripeEventHandler
    def self.call(event) = new(event).call

    def initialize(event)
      @event = event
    end

    def call
      return :duplicate unless ProcessedStripeEvent.process(@event.id, @event.type)

      case @event.type
      when "checkout.session.completed"     then handle_checkout_completed
      when "customer.subscription.created"  then handle_subscription_upsert(audit_action: "subscription.created")
      when "customer.subscription.updated"  then handle_subscription_upsert(audit_action: "subscription.updated")
      when "customer.subscription.deleted"  then handle_subscription_deleted
      when "invoice.payment_failed"         then handle_payment_failed
      else
        :ignored
      end
    end

    private
      attr_reader :event

      def data_object
        event.data.object
      end

      def find_account(account_id_from_metadata: nil, customer_id: nil)
        if account_id_from_metadata.present?
          Account.find_by(id: account_id_from_metadata)
        elsif customer_id.present?
          Subscription.find_by(stripe_customer_id: customer_id)&.account
        end
      end

      def handle_checkout_completed
        session = data_object
        account = find_account(
          account_id_from_metadata: session.client_reference_id || session.metadata&.[]("account_id"),
          customer_id: session.customer
        )
        return :no_account unless account
        :ok
      end

      def handle_subscription_upsert(audit_action:)
        stripe_subscription = data_object
        account = find_account(
          account_id_from_metadata: stripe_subscription.metadata&.[]("account_id"),
          customer_id: stripe_subscription.customer
        )
        return :no_account unless account

        subscription = account.subscription || account.build_subscription
        subscription.assign_attributes(
          stripe_customer_id:     stripe_subscription.customer,
          stripe_subscription_id: stripe_subscription.id,
          stripe_price_id:        stripe_subscription.items.data.first&.price&.id,
          plan:                   stripe_subscription.items.data.first&.price&.nickname,
          status:                 stripe_subscription.status,
          current_period_end:     timestamp_to_time(stripe_subscription.current_period_end),
          cancel_at_period_end:   !!stripe_subscription.cancel_at_period_end,
          trial_ends_at:          timestamp_to_time(stripe_subscription.trial_end),
          metadata:               stripe_subscription.metadata&.to_h || {}
        )
        subscription.save!

        AuditLog.create!(
          action:    audit_action,
          account:   account,
          user:      nil,
          auditable: subscription,
          metadata:  { stripe_event_id: event.id, status: subscription.status }
        )

        :ok
      end

      def handle_subscription_deleted
        stripe_subscription = data_object
        subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
        return :no_account unless subscription

        subscription.update!(status: "canceled", cancel_at_period_end: true)

        AuditLog.create!(
          action:    "subscription.canceled",
          account:   subscription.account,
          auditable: subscription,
          metadata:  { stripe_event_id: event.id }
        )
        :ok
      end

      def handle_payment_failed
        invoice = data_object
        account = find_account(customer_id: invoice.customer)
        return :no_account unless account

        AuditLog.create!(
          action:   "invoice.payment_failed",
          account:  account,
          metadata: { stripe_event_id: event.id, invoice_id: invoice.id, amount_due: invoice.amount_due }
        )
        :ok
      end

      def timestamp_to_time(ts)
        return nil if ts.blank?
        Time.at(ts.to_i).utc
      end
  end
end
