require "test_helper"

class AuditLoggingTest < ActionDispatch::IntegrationTest
  test "signup records user.signup and account.created" do
    assert_difference -> { AuditLog.where(action: "user.signup").count }     => 1,
                      -> { AuditLog.where(action: "account.created").count } => 1 do
      post registration_path, params: {
        user: {
          name: "Audit Test",
          email_address: "audit@example.com",
          password: "secret-pass",
          password_confirmation: "secret-pass"
        }
      }
    end
  end

  test "successful login records user.login" do
    assert_difference -> { AuditLog.where(action: "user.login").count } => 1 do
      post session_path, params: { email_address: users(:one).email_address, password: "password" }
    end
  end

  test "failed login records user.login_failed and stores attempted email in metadata" do
    assert_difference -> { AuditLog.where(action: "user.login_failed").count } => 1 do
      post session_path, params: { email_address: "ghost@example.com", password: "anything" }
    end

    log = AuditLog.where(action: "user.login_failed").last
    assert_equal "ghost@example.com", log.metadata["email_address"]
  end

  test "logout records user.logout" do
    sign_in_as(users(:one))

    assert_difference -> { AuditLog.where(action: "user.logout").count } => 1 do
      delete session_path
    end
  end

  test "password reset request records user.password_reset_requested" do
    assert_difference -> { AuditLog.where(action: "user.password_reset_requested").count } => 1 do
      post passwords_path, params: { email_address: users(:one).email_address }
    end
  end
end
