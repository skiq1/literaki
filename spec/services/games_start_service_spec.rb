require "rails_helper"

RSpec.describe Games::StartService do
  it "starts waiting game with two players" do
    user = User.create!(username: "marek", api_token: "token-1")
    opponent = User.create!(username: "ania", api_token: "token-2")
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call

    result = described_class.new(game: game).call

    expect(result).to be_success
    expect(game.reload.status).to eq("active")
    expect(game.game_players.map { |player| player.rack.size }).to eq([7, 7])
  end
end
