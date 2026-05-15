require "test_helper"

class PurgeOldRequestLogsJobTest < ActiveJob::TestCase
  test "deletes records older than retention period" do
    fresh = RequestLog.create!(method: "GET", path: "/x", status: 200, duration_ms: 1, category: "auth", created_at: 5.days.ago)
    old   = RequestLog.create!(method: "GET", path: "/x", status: 200, duration_ms: 1, category: "auth", created_at: 90.days.ago)

    PurgeOldRequestLogsJob.new.perform

    assert RequestLog.exists?(fresh.id)
    assert_not RequestLog.exists?(old.id)
  end

  test "honors custom retention" do
    one_day_old  = RequestLog.create!(method: "GET", path: "/x", status: 200, duration_ms: 1, category: "auth", created_at: 1.day.ago)
    ten_days_old = RequestLog.create!(method: "GET", path: "/x", status: 200, duration_ms: 1, category: "auth", created_at: 10.days.ago)

    PurgeOldRequestLogsJob.new.perform(retention: 7.days)

    assert RequestLog.exists?(one_day_old.id)
    assert_not RequestLog.exists?(ten_days_old.id)
  end
end
