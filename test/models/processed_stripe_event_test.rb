require "test_helper"

class ProcessedStripeEventTest < ActiveSupport::TestCase
  test "process returns true on first call and false on duplicate" do
    assert ProcessedStripeEvent.process("evt_1", "subscription.created")
    assert_not ProcessedStripeEvent.process("evt_1", "subscription.created")
    assert_equal 1, ProcessedStripeEvent.where(stripe_event_id: "evt_1").count
  end
end
