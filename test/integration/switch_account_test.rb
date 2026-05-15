require "test_helper"

class SwitchAccountTest < ActionDispatch::IntegrationTest
  test "user that belongs to multiple accounts can switch between them" do
    user = users(:two)
    sign_in_as(user)

    post switch_account_path(accounts(:globex))
    assert_redirected_to root_path

    post switch_account_path(accounts(:acme))
    assert_redirected_to root_path
  end

  test "user cannot switch to an account they do not belong to" do
    sign_in_as(users(:one))

    post switch_account_path(accounts(:globex))
    assert_response :not_found
  end
end
