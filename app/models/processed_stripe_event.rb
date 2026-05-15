class ProcessedStripeEvent < ApplicationRecord
  validates :stripe_event_id, presence: true
  validates :event_type, :processed_at, presence: true

  def self.process(event_id, event_type)
    create!(stripe_event_id: event_id, event_type: event_type, processed_at: Time.current)
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end
end
