module RequestLogging
  extend ActiveSupport::Concern

  CATEGORY_PREFIXES = {
    "webhooks"      => "webhook",
    "billing"       => "payment",
    "sessions"      => "auth",
    "registrations" => "auth",
    "passwords"     => "auth",
    "admin"         => "admin",
    "api"           => "api"
  }.freeze

  included do
    around_action :record_request_log
  end

  private
    def record_request_log
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Current.request_id = request.request_id
      yield
    ensure
      category = request_log_category
      if category
        duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).to_i

        begin
          RequestLogCreateJob.perform_later(
            {
              account_id:  Current.account&.id,
              user_id:     Current.user&.id,
              request_id:  request.request_id,
              method:      request.request_method,
              path:        request.path,
              status:      response&.status,
              duration_ms: duration_ms,
              category:    category,
              params:      filtered_request_params,
              ip:          request.remote_ip,
              user_agent:  request.user_agent,
              created_at:  Time.current
            }
          )
        rescue StandardError => e
          Rails.logger.warn("[request-logging] failed to enqueue: #{e.class}: #{e.message}")
        end
      end
    end

    def request_log_category
      CATEGORY_PREFIXES.each do |prefix, category|
        return category if controller_path == prefix || controller_path.start_with?("#{prefix}/")
      end
      nil
    end

    def filtered_request_params
      request.filtered_parameters.except("controller", "action", "format")
    end
end
