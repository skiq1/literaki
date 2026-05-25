module Games
  class JoinService < ApplicationService
    def initialize(game:, user:)
      @game = game
      @user = user
    end

    def call
      return failure("Game is not waiting for players") unless game.status == "waiting"
      return failure("User already joined this game") if game.game_players.exists?(user: user)
      return failure("Game already has two players") if game.game_players.count >= 2

      game.game_players.create!(user: user, position: game.game_players.count + 1)
      success(game.reload)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :game, :user
  end
end
