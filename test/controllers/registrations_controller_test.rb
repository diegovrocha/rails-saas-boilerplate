require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new renders" do
    get new_registration_path
    assert_response :success
  end

  test "create with valid params signs the user in and redirects to root" do
    post registration_path, params: {
      user: {
        name: "Alice",
        email_address: "alice@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }

    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "create with invalid params renders new and does not sign in" do
    post registration_path, params: {
      user: {
        name: "",
        email_address: "bad",
        password: "x",
        password_confirmation: "y"
      }
    }

    assert_response :unprocessable_entity
    assert_nil cookies[:session_id].presence
  end
end
