require "rails_helper"

RSpec.describe Games::ClockSweepJob, type: :job do
  let(:user) { User.create!(username: "marek", api_token: "token-1") }
  let(:opponent) { User.create!(username: "ania", api_token: "token-2") }

  it "syncs active timed games" do
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call
    Games::StartService.new(game: game).call
    game.game_players.find_by!(user: user).update!(remaining_time_ms: 1_000)
    game.game_players.find_by!(user: opponent).update!(remaining_time_ms: 0)
    game.update!(current_turn_user: user, turn_started_at: 2.seconds.ago)

    described_class.perform_now

    expect(game.reload.status).to eq("finished")
  end
end
