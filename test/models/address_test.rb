require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "belongs to account" do
    addr = addresses(:acme_address)
    assert_equal accounts(:acme), addr.account
  end

  test "country must be 2 chars when present" do
    assert_not Address.new(account: accounts(:globex), country: "BRA").valid?
    assert Address.new(account: accounts(:globex), country: "BR").valid?
    assert Address.new(account: accounts(:globex), country: nil).valid?
  end
end
