class Current < ActiveSupport::CurrentAttributes
  attribute :session, :account, :request_id

  delegate :user, to: :session, allow_nil: true
end
