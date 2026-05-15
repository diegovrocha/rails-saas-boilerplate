require "test_helper"

class RequestLoggingTest < ActionDispatch::IntegrationTest
  test "POST /session enqueues RequestLogCreateJob with category=auth" do
    perform_enqueued_jobs do
      assert_difference -> { RequestLog.where(category: "auth").count } => 1 do
        post session_path, params: { email_address: users(:one).email_address, password: "password" }
      end
    end

    log = RequestLog.where(category: "auth").last
    assert_equal "POST", log.method
    assert_equal "/session", log.path
    assert_not_nil log.duration_ms
  end

  test "failed login still records RequestLog with non-2xx status" do
    perform_enqueued_jobs do
      assert_difference -> { RequestLog.where(category: "auth").count } => 1 do
        post session_path, params: { email_address: users(:one).email_address, password: "wrong" }
      end
    end

    log = RequestLog.where(category: "auth").order(:id).last
    assert_includes [ 302, 422 ], log.status
  end

  test "/up healthcheck does NOT create a RequestLog" do
    perform_enqueued_jobs do
      assert_no_difference -> { RequestLog.count } do
        get "/up"
      end
    end
  end

  test "home page does NOT create a RequestLog" do
    perform_enqueued_jobs do
      assert_no_difference -> { RequestLog.count } do
        get root_path
      end
    end
  end

  test "POST /registration is logged under category=auth" do
    perform_enqueued_jobs do
      assert_difference -> { RequestLog.where(category: "auth").count } => 1 do
        post registration_path, params: {
          user: {
            name: "Hank",
            email_address: "hank@example.com",
            password: "secret-pass",
            password_confirmation: "secret-pass"
          }
        }
      end
    end
  end
end
