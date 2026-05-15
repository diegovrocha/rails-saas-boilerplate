require "test_helper"

class AuthFlowTest < ActionDispatch::IntegrationTest
  test "login with valid credentials sets cookie and redirects to root" do
    user = users(:one)
    post session_path, params: { email_address: user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "login with invalid credentials redirects to new session with alert" do
    user = users(:one)
    post session_path, params: { email_address: user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id].presence
  end

  test "logout terminates session" do
    sign_in_as(users(:one))

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id].to_s
  end
end
