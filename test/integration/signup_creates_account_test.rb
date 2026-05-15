require "test_helper"

class SignupCreatesAccountTest < ActionDispatch::IntegrationTest
  test "POST /registration creates User, Account named after user, AccountUser owner, and starts a session" do
    assert_difference -> { User.count } => 1,
                      -> { Account.count } => 1,
                      -> { AccountUser.count } => 1 do
      post registration_path, params: {
        user: {
          name: "Jane Doe",
          email_address: "jane@example.com",
          password: "secret-pass",
          password_confirmation: "secret-pass"
        }
      }
    end

    assert_redirected_to root_path
    assert cookies[:session_id].present?

    user    = User.find_by!(email_address: "jane@example.com")
    account = Account.order(:id).last

    assert_equal "Jane Doe", account.name
    assert_equal "owner", AccountUser.find_by(user: user, account: account).role
  end

  test "validation failure rolls back: no User, Account, or AccountUser are persisted" do
    assert_no_difference [ -> { User.count }, -> { Account.count }, -> { AccountUser.count } ] do
      post registration_path, params: {
        user: {
          name: "",
          email_address: "invalid",
          password: "short",
          password_confirmation: "mismatch"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "new is reachable without authentication" do
    get new_registration_path
    assert_response :success
  end
end
