class GamePlayer < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :user_id, uniqueness: { scope: :game_id }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :score, :passed_turns_count, numericality: { greater_than_or_equal_to: 0 }
end
