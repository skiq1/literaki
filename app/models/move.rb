class Move < ApplicationRecord
  MOVE_TYPES = %w[place_tiles exchange_tiles pass resign].freeze

  belongs_to :game
  belongs_to :user

  validates :move_type, presence: true, inclusion: { in: MOVE_TYPES }
  validates :score, numericality: { greater_than_or_equal_to: 0 }
end
