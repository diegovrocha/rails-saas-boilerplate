require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end

  teardown do
    Rack::Attack.reset!
  end

  test "6th POST /session within the window returns 429 with Retry-After" do
    5.times do
      post session_path, params: { email_address: "anyone@example.com", password: "nope" }
      assert_not_equal 429, response.status
    end

    post session_path, params: { email_address: "anyone@example.com", password: "nope" }
    assert_equal 429, response.status
    assert response.headers["Retry-After"].present?
  end
end
