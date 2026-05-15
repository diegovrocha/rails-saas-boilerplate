require "test_helper"

class AccountUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner   = users(:one)
    @member  = users(:two)
    @account = accounts(:acme)
  end

  test "index lists members of the current account for a member" do
    sign_in_as(@member)
    get account_users_path
    assert_response :success
  end

  test "create invites an existing user as member" do
    sign_in_as(@owner)
    user = User.create!(name: "Newbie", email_address: "newbie@example.com", password: "password")

    assert_difference -> { AccountUser.where(account: @account).count }, 1 do
      post account_users_path, params: { account_user: { email_address: user.email_address, role: "member" } }
    end
    assert_redirected_to account_users_path
  end

  test "create returns error when user does not exist" do
    sign_in_as(@owner)

    assert_no_difference -> { AccountUser.count } do
      post account_users_path, params: { account_user: { email_address: "ghost@example.com", role: "member" } }
    end
    assert_redirected_to account_users_path
  end

  test "update role of an existing member" do
    sign_in_as(@owner)
    target = account_users(:two_member_acme)

    patch account_user_path(target), params: { account_user: { role: "admin" } }
    assert_redirected_to account_users_path
    assert_equal "admin", target.reload.role
  end

  test "destroy removes a member" do
    sign_in_as(@owner)
    target = account_users(:two_member_acme)

    assert_difference -> { AccountUser.count }, -1 do
      delete account_user_path(target)
    end
  end

  test "destroy is blocked when removing the last owner" do
    sign_in_as(@owner)
    target = account_users(:one_owns_acme)

    assert_no_difference -> { AccountUser.count } do
      delete account_user_path(target)
    end
  end

  test "non-admin member cannot create" do
    sign_in_as(@member)

    other = User.create!(name: "Other", email_address: "other@example.com", password: "password")

    assert_no_difference -> { AccountUser.count } do
      post account_users_path, params: { account_user: { email_address: other.email_address, role: "member" } }
    end
  end
end
