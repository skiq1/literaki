class User < ApplicationRecord
  has_many :game_players, dependent: :destroy
  has_many :games, through: :game_players
  has_many :moves, dependent: :destroy

  validates :username, presence: true
  validates :api_token, presence: true, uniqueness: true
  validates :games_played, :games_won, :total_score, numericality: { greater_than_or_equal_to: 0 }
end
