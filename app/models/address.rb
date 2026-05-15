class Address < ApplicationRecord
  belongs_to :account

  validates :country, length: { is: 2 }, allow_blank: true
end
