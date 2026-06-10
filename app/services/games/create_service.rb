module Games
  class CreateService < ApplicationService
    def initialize(user:, time_limit_enabled: true)
      @user = user
      @time_limit_enabled = ActiveModel::Type::Boolean.new.cast(time_limit_enabled)
    end

    def call
      game = nil

      Game.transaction do
        game = Game.create!(status: "waiting", board: {}, bag: [], time_limit_enabled: time_limit_enabled)
        game.game_players.create!(user: user, position: 1)
      end

      success(game)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :user, :time_limit_enabled
  end
end
