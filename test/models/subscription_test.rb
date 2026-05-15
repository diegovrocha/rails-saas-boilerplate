require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  def base_attrs(**overrides)
    {
      account: accounts(:acme),
      stripe_subscription_id: "sub_x",
      status: "active",
      current_period_end: 30.days.from_now
    }.merge(overrides)
  end

  test "active? for active and trialing" do
    assert Subscription.new(base_attrs(status: "active")).active?
    assert Subscription.new(base_attrs(status: "trialing")).active?
    assert_not Subscription.new(base_attrs(status: "past_due")).active?
  end

  test "in_trial? requires trialing status and future trial_ends_at" do
    sub = Subscription.new(base_attrs(status: "trialing", trial_ends_at: 1.day.from_now))
    assert sub.in_trial?

    expired = Subscription.new(base_attrs(status: "trialing", trial_ends_at: 1.day.ago))
    assert_not expired.in_trial?
  end

  test "expired? when period ended and not flagged for cancel" do
    sub = Subscription.new(base_attrs(status: "active", current_period_end: 1.day.ago, cancel_at_period_end: false))
    assert sub.expired?

    flagged = Subscription.new(base_attrs(status: "active", current_period_end: 1.day.ago, cancel_at_period_end: true))
    assert_not flagged.expired?
  end

  test "Account delegates expose subscription state" do
    account = accounts(:acme)
    sub = Subscription.create!(account: account, stripe_subscription_id: "sub_x", status: "active", plan: "Pro")

    assert account.reload.has_active_subscription?
    assert_equal "active", account.subscription_status
    assert_equal "Pro", account.current_plan
  end
end
