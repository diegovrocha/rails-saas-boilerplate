return unless Rails.env.production? || Rails.env.staging?

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |event|
    payload = event.payload
    {
      request_id: payload[:request_id],
      user_id:    payload[:user_id],
      account_id: payload[:account_id],
      ip:         payload[:ip],
      params:     payload[:params]&.except("controller", "action", "format")
    }
  end
end
