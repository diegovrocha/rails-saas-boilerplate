require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid with minimum fields" do
    assert Account.new(name: "Foo").valid?
  end

  test "name must be present and >= 2 chars" do
    assert_not Account.new(name: nil).valid?
    assert_not Account.new(name: "A").valid?
    assert Account.new(name: "AB").valid?
  end

  test "cpf must match 11 digits when present" do
    assert_not Account.new(name: "Co", cpf: "123").valid?
    assert_not Account.new(name: "Co", cpf: "abcdefghijk").valid?
    assert Account.new(name: "Co", cpf: "12345678901").valid?
  end

  test "cpf is unique when present" do
    Account.create!(name: "AA", cpf: "12345678901")
    dup = Account.new(name: "BB", cpf: "12345678901")
    assert_not dup.valid?
  end

  test "phone must match 10-11 digits when present" do
    assert_not Account.new(name: "Co", phone: "123").valid?
    assert Account.new(name: "Co", phone: "1199999999").valid?
    assert Account.new(name: "Co", phone: "11999999999").valid?
  end

  test "active scope" do
    assert_includes Account.active, accounts(:acme)
    assert_not_includes Account.active, accounts(:inactive)
  end

  test "billing_type enum" do
    a = accounts(:acme)
    assert a.billing_credit_card?
    assert_not a.billing_free?
  end

  test "owner is the user with owner role" do
    assert_equal users(:one), accounts(:acme).owner
  end

  test "admin_users includes owner and admin" do
    assert_includes accounts(:acme).admin_users, users(:one)
    assert_not_includes accounts(:acme).admin_users, users(:two)
  end

  test "member_users excludes owners and admins" do
    assert_includes accounts(:acme).member_users, users(:two)
    assert_not_includes accounts(:acme).member_users, users(:one)
  end

  test "sync_allowed? mirrors active?" do
    assert accounts(:acme).sync_allowed?
    assert_not accounts(:inactive).sync_allowed?
  end
end
