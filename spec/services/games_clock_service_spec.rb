require "rails_helper"

RSpec.describe Games::ClockService do
  let(:user) { User.create!(username: "marek", api_token: "token-1") }
  let(:opponent) { User.create!(username: "ania", api_token: "token-2") }

  it "moves turn to the player who still has time" do
    game = started_game
    game.game_players.find_by!(user: user).update!(remaining_time_ms: 1_000)
    game.game_players.find_by!(user: opponent).update!(remaining_time_ms: 600_000)
    game.update!(current_turn_user: user, turn_started_at: 2.seconds.ago)

    described_class.new(game: game).call

    expect(game.reload.status).to eq("active")
    expect(game.current_turn_user_id).to eq(opponent.id)
    expect(game.game_players.find_by!(user: user).remaining_time_ms).to eq(0)
  end

  it "finishes game when both players have no time left" do
    game = started_game
    game.game_players.find_by!(user: user).update!(remaining_time_ms: 1_000)
    game.game_players.find_by!(user: opponent).update!(remaining_time_ms: 0)
    game.update!(current_turn_user: user, turn_started_at: 2.seconds.ago)

    described_class.new(game: game).call

    expect(game.reload.status).to eq("finished")
    expect(game.current_turn_user_id).to be_nil
  end

  it "does not count time when time limit is disabled" do
    game = started_game(time_limit_enabled: false)
    game_player = game.game_players.find_by!(user: user)
    game.update!(current_turn_user: user, turn_started_at: 2.minutes.ago)

    described_class.new(game: game).call

    expect(game_player.reload.remaining_time_ms).to eq(Games::ClockService::DEFAULT_TIME_LIMIT_MS)
    expect(game.reload.current_turn_user_id).to eq(user.id)
  end

  def started_game(time_limit_enabled: true)
    game = Games::CreateService.new(user: user, time_limit_enabled: time_limit_enabled).call.value
    Games::JoinService.new(game: game, user: opponent).call
    Games::StartService.new(game: game).call.value
  end
end
