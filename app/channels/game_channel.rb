class GameChannel < ApplicationCable::Channel
  def subscribed
    game = Game.find_by(id: params[:game_id])
    return reject unless game&.game_players&.exists?(user: current_user)

    stream_from Games::BroadcastService.stream_name(game, current_user)
  end
end
