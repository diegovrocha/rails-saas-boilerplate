class RequestLogCreateJob < ApplicationJob
  queue_as :default

  def perform(attributes)
    RequestLog.create!(attributes)
  end
end
