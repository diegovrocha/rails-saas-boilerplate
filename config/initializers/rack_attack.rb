class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  throttle("session/ip", limit: 5, period: 5.minutes) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  throttle("registration/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/registration" && req.post?
  end

  throttle("passwords/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/passwords" && req.post?
  end

  throttle("webhooks/stripe/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/webhooks/stripe" && req.post?
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    now = match_data[:epoch_time] || Time.now.to_i
    period = match_data[:period].to_i
    retry_after = period - (now % period)

    [
      429,
      {
        "Content-Type" => "text/plain; charset=utf-8",
        "Retry-After" => retry_after.to_s
      },
      [ I18n.t("flash.rate_limited", default: "Too many requests. Try again later.") ]
    ]
  end
end
