module Moves
  class ApplyMoveService < ApplicationService
    def initialize(game:, user:, move_type:, tiles: [], words: [], score: 0)
      @game = game
      @user = user
      @move_type = move_type
      @tiles = tiles
      @words = words
      @score = score
    end

    def call
      move = game.moves.create!(
        user: user,
        move_type: move_type,
        tiles: tiles,
        words: words,
        score: score
      )
      success(move)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :game, :user, :move_type, :tiles, :words, :score
  end
end
