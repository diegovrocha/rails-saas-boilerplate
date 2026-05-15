module Auditing
  extend ActiveSupport::Concern

  private
    def audit!(action, auditable: nil, user: nil, account: nil, **metadata)
      AuditLog.create!(
        action:     action.to_s,
        user:       user || Current.user,
        account:    account || Current.account,
        auditable:  auditable,
        metadata:   metadata,
        ip:         request.remote_ip,
        user_agent: request.user_agent
      )
    end
end
