class PurgeOldRequestLogsJob < ApplicationJob
  queue_as :default

  RETENTION = 60.days

  def perform(retention: RETENTION, batch_size: 5_000)
    cutoff = retention.ago
    loop do
      deleted = RequestLog.where("created_at < ?", cutoff).limit(batch_size).delete_all
      break if deleted < batch_size
    end
  end
end
