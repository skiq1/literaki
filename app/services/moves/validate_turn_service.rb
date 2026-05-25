module Moves
  class ValidateTurnService < ApplicationService
    def initialize(game:, user:)
      @game = game
      @user = user
    end

    def call
      return failure("Game is not active") unless game.status == "active"
      return failure("User is not a player in this game") unless game.game_players.exists?(user: user)
      return failure("It is not this user's turn") unless game.current_turn_user_id == user.id

      success
    end

    private

    attr_reader :game, :user
  end
end
