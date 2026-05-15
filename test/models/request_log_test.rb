require "test_helper"

class RequestLogTest < ActiveSupport::TestCase
  test "scopes filter as expected" do
    base = { method: "POST", path: "/x", duration_ms: 50, category: "auth", created_at: Time.current }
    RequestLog.create!(base.merge(status: 200))
    RequestLog.create!(base.merge(status: 422))
    RequestLog.create!(base.merge(status: 500, duration_ms: 2_500))

    assert_equal 2, RequestLog.errors_only.count
    assert_equal 1, RequestLog.slow.count
    assert_equal 3, RequestLog.by_category("auth").count
  end

  test "error? and slow?" do
    log = RequestLog.new(status: 500, duration_ms: 1_500)
    assert log.error?
    assert log.slow?
  end

  test "period_ago helper" do
    assert_in_delta 1.hour.ago.to_i,   RequestLog.period_ago("1h").to_i,   5
    assert_in_delta 60.days.ago.to_i,  RequestLog.period_ago("60d").to_i,  5
    assert_in_delta 24.hours.ago.to_i, RequestLog.period_ago("bogus").to_i, 5
  end
end
