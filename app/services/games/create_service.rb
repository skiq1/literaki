module Games
  class CreateService < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      game = nil

      Game.transaction do
        game = Game.create!(status: "waiting", board: {}, bag: [])
        game.game_players.create!(user: user, position: 1)
      end

      success(game)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :user
  end
end
