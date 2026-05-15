require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner   = users(:one)
    @member  = users(:two)
    @account = accounts(:acme)
  end

  test "show renders for member of the account" do
    sign_in_as(@member)
    get account_path(@account)
    assert_response :success
  end

  test "edit renders for admin/owner" do
    sign_in_as(@owner)
    get edit_account_path(@account)
    assert_response :success
  end

  test "edit is forbidden for non-admin member" do
    sign_in_as(@member)
    get edit_account_path(@account)
    assert_redirected_to root_path
    follow_redirect!
    assert_match(/permiss/i, flash[:alert].to_s)
  end

  test "update succeeds for owner" do
    sign_in_as(@owner)
    patch account_path(@account), params: { account: { name: "Acme Updated" } }
    assert_redirected_to account_path(@account)
    assert_equal "Acme Updated", @account.reload.name
  end

  test "update fails for non-admin member" do
    sign_in_as(@member)
    patch account_path(@account), params: { account: { name: "Hacked" } }
    assert_redirected_to root_path
    assert_not_equal "Hacked", @account.reload.name
  end

  test "switch updates current_account_id" do
    sign_in_as(@member)
    post switch_account_path(accounts(:globex))
    assert_redirected_to root_path
  end
end
