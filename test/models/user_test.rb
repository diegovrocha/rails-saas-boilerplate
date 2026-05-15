require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal "downcased@example.com", user.email_address
  end

  test "requires name" do
    user = User.new(email_address: "n@example.com", password: "secret123")
    assert_not user.valid?
    assert_includes user.errors[:name], "não pode ficar em branco"
  end

  test "requires valid email format" do
    user = User.new(name: "X", email_address: "not-an-email", password: "secret123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "não é válido"
  end

  test "admin_of? and owner_of? for fixtures" do
    one = users(:one)
    two = users(:two)
    acme = accounts(:acme)

    assert one.owner_of?(acme)
    assert one.admin_of?(acme)
    assert_not two.owner_of?(acme)
    assert_not two.admin_of?(acme)
  end
end
