class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Auditing
  include RequestLogging

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_current_account
  after_action :verify_pundit_usage

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.request_id
    payload[:user_id]    = Current.user&.id
    payload[:account_id] = Current.account&.id
    payload[:ip]         = request.remote_ip
    payload[:params]     = request.filtered_parameters
  end

  private
    def pundit_user
      Current.user
    end

    SKIP_PUNDIT_CONTROLLERS = %w[
      sessions
      passwords
      registrations
      home
      rails/health
      webhooks
      billing
    ].freeze

    def skip_pundit?
      SKIP_PUNDIT_CONTROLLERS.any? { |prefix| controller_path == prefix || controller_path.start_with?("#{prefix}/") }
    end

    def verify_pundit_usage
      return if skip_pundit?

      if action_name == "index"
        verify_policy_scoped
      else
        verify_authorized
      end
    end

    def set_current_account
      return unless Current.user

      requested_id = session[:current_account_id]
      account = Current.user.accounts.find_by(id: requested_id) if requested_id
      account ||= Current.user.accounts.first

      Current.account = account
      session[:current_account_id] = account&.id
    end

    def user_not_authorized
      flash[:alert] = I18n.t("flash.not_authorized")
      redirect_back fallback_location: root_path
    end
end
