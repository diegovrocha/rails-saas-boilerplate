require "test_helper"

module Billing
  class StripeEventHandlerTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:acme)
    end

    test "customer.subscription.created upserts Subscription + audit logs once (idempotent)" do
      event = build_event("customer_subscription_created.json", account_id: @account.id)

      assert_difference -> { Subscription.count } => 1,
                        -> { AuditLog.where(action: "subscription.created").count } => 1,
                        -> { ProcessedStripeEvent.count } => 1 do
        Billing::StripeEventHandler.call(event)
      end

      assert_no_difference [ -> { Subscription.count },
                             -> { AuditLog.where(action: "subscription.created").count },
                             -> { ProcessedStripeEvent.count } ] do
        Billing::StripeEventHandler.call(event)
      end

      sub = @account.reload.subscription
      assert_equal "active", sub.status
      assert_equal "sub_test_123", sub.stripe_subscription_id
    end

    test "customer.subscription.updated changes status on existing subscription" do
      create_event = build_event("customer_subscription_created.json", account_id: @account.id)
      Billing::StripeEventHandler.call(create_event)

      update_event = build_event("customer_subscription_updated.json", account_id: @account.id)

      assert_difference -> { AuditLog.where(action: "subscription.updated").count } => 1 do
        Billing::StripeEventHandler.call(update_event)
      end

      assert_equal "past_due", @account.reload.subscription.status
    end

    test "customer.subscription.deleted marks subscription canceled" do
      Billing::StripeEventHandler.call(build_event("customer_subscription_created.json", account_id: @account.id))

      delete_event = build_event("customer_subscription_deleted.json", account_id: @account.id)

      assert_difference -> { AuditLog.where(action: "subscription.canceled").count } => 1 do
        Billing::StripeEventHandler.call(delete_event)
      end

      assert_equal "canceled", @account.reload.subscription.status
      assert @account.subscription.cancel_at_period_end?
    end

    test "invoice.payment_failed records AuditLog when account is known via customer_id" do
      Billing::StripeEventHandler.call(build_event("customer_subscription_created.json", account_id: @account.id))

      payfail_event = build_event("invoice_payment_failed.json", account_id: @account.id)

      assert_difference -> { AuditLog.where(action: "invoice.payment_failed").count } => 1 do
        Billing::StripeEventHandler.call(payfail_event)
      end
    end

    test "checkout.session.completed is a no-op when subscription not yet created" do
      event = build_event("checkout_session_completed.json", account_id: @account.id)
      assert_nothing_raised { Billing::StripeEventHandler.call(event) }
    end

    test "duplicate event returns :duplicate" do
      event = build_event("customer_subscription_created.json", account_id: @account.id)
      Billing::StripeEventHandler.call(event)
      assert_equal :duplicate, Billing::StripeEventHandler.call(event)
    end

    private
      def build_event(fixture, account_id:)
        path = Rails.root.join("test/fixtures/stripe", fixture)
        payload = format(File.read(path), account_id: account_id)
        Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
      end
  end
end
