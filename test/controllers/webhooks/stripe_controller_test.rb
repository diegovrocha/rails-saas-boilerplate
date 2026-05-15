require "test_helper"

module Webhooks
  class StripeControllerTest < ActionDispatch::IntegrationTest
    WEBHOOK_SECRET = "whsec_test_secret_for_minitest".freeze

    setup do
      @account = accounts(:acme)
      @payload = format(File.read(Rails.root.join("test/fixtures/stripe/customer_subscription_created.json")), account_id: @account.id)
      Rails.application.credentials.stripe ||= {}
      @original_secret = Rails.application.credentials.stripe[:webhook_secret]
      Rails.application.credentials.stripe[:webhook_secret] = WEBHOOK_SECRET
    end

    teardown do
      Rails.application.credentials.stripe[:webhook_secret] = @original_secret
    end

    test "valid signature dispatches handler and returns 200" do
      assert_difference -> { Subscription.count } => 1,
                        -> { AuditLog.where(action: "subscription.created").count } => 1 do
        post webhooks_stripe_path, params: @payload, headers: signed_headers(@payload)
      end
      assert_response :ok
    end

    test "invalid signature returns 400" do
      post webhooks_stripe_path, params: @payload, headers: { "Content-Type" => "application/json", "Stripe-Signature" => "t=1,v1=bogus" }
      assert_response :bad_request
    end

    test "missing signature header returns 400" do
      post webhooks_stripe_path, params: @payload, headers: { "Content-Type" => "application/json" }
      assert_response :bad_request
    end

    test "duplicate event is idempotent" do
      headers = signed_headers(@payload)

      2.times do
        post webhooks_stripe_path, params: @payload, headers: headers
      end

      assert_equal 1, Subscription.where(stripe_subscription_id: "sub_test_123").count
      assert_equal 1, AuditLog.where(action: "subscription.created").count
    end

    test "webhook request is logged with category=webhook" do
      perform_enqueued_jobs do
        assert_difference -> { RequestLog.where(category: "webhook").count } => 1 do
          post webhooks_stripe_path, params: @payload, headers: signed_headers(@payload)
        end
      end
    end

    private
      def signed_headers(payload)
        timestamp = Time.now
        signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, WEBHOOK_SECRET)
        header    = Stripe::Webhook::Signature.generate_header(timestamp, signature)
        {
          "Content-Type" => "application/json",
          "Stripe-Signature" => header
        }
      end
  end
end
