module Games
  class BroadcastService
    EVENT_GAME_CREATED = "game.created".freeze
    EVENT_GAME_UPDATED = "game.updated".freeze
    EVENT_MOVE_CREATED = "move.created".freeze

    def self.call(game:, event:, move: nil)
      new(game: game, event: event, move: move).call
    end

    def self.stream_name(game, user)
      "game:#{game.id}:user:#{user.id}"
    end

    def initialize(game:, event:, move: nil)
      @game = game
      @event = event
      @move = move
    end

    def call
      game.reload
      game.users.find_each do |user|
        ActionCable.server.broadcast(
          self.class.stream_name(game, user),
          payload_for(user)
        )
      end
    end

    private

    attr_reader :game, :event, :move

    def payload_for(user)
      payload = {
        event: event,
        game: GameSerializer.new(game, current_user: user).as_json
      }
      payload[:move] = MoveSerializer.render(move) if move
      payload
    end
  end
end
