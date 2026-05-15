require "test_helper"

class AccountUserTest < ActiveSupport::TestCase
  test "role defaults to member" do
    au = AccountUser.new
    assert_equal "member", au.role
  end

  test "user/account combination must be unique" do
    existing = account_users(:one_owns_acme)
    dup = AccountUser.new(user: existing.user, account: existing.account, role: "member")
    assert_not dup.valid?
  end

  test "different account allowed for same user" do
    au = AccountUser.new(user: users(:one), account: accounts(:globex), role: "member")
    assert au.valid?
  end

  test "role enum methods" do
    au = account_users(:one_owns_acme)
    assert au.role_owner?
    assert_not au.role_member?
  end
end
