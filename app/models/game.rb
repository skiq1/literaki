class Game < ApplicationRecord
  STATUSES = %w[waiting active finished cancelled].freeze

  has_many :game_players, -> { order(:position) }, dependent: :destroy
  has_many :users, through: :game_players
  has_many :moves, dependent: :destroy

  belongs_to :current_turn_user, class_name: "User", optional: true
  belongs_to :winner, class_name: "User", optional: true

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :time_limit_enabled, inclusion: { in: [ true, false ] }
end
