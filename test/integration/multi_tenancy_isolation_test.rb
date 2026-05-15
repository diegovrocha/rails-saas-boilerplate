require "test_helper"

class MultiTenancyIsolationTest < ActionDispatch::IntegrationTest
  test "user logged into account A cannot view account B (404 from policy_scope)" do
    sign_in_as(users(:one))

    get account_path(accounts(:globex))
    assert_response :not_found
  end

  test "user logged into account A can view their own account" do
    sign_in_as(users(:one))

    get account_path(accounts(:acme))
    assert_response :success
  end

  test "user cannot edit an account they do not belong to" do
    sign_in_as(users(:one))

    get edit_account_path(accounts(:globex))
    assert_response :not_found
  end
end
