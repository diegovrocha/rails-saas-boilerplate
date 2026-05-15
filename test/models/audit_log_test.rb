require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "requires action" do
    assert_not AuditLog.new.valid?
  end

  test "stores metadata as json hash" do
    log = AuditLog.create!(action: "test.event", metadata: { foo: "bar", count: 3 })
    assert_equal "bar", log.reload.metadata["foo"]
    assert_equal 3,     log.metadata["count"]
  end

  test "scopes" do
    one_user    = users(:one)
    one_account = accounts(:acme)

    AuditLog.create!(action: "user.login", user: one_user, account: one_account)
    AuditLog.create!(action: "user.logout", user: one_user, account: one_account)
    AuditLog.create!(action: "account.created", user: users(:two), account: accounts(:globex))

    assert_equal 2, AuditLog.for_user(one_user.id).count
    assert_equal 2, AuditLog.for_account(one_account.id).count
    assert_equal 1, AuditLog.with_action("account.created").count
  end
end
