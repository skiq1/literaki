require "rails_helper"

RSpec.describe Games::BroadcastService do
  let(:user) { User.create!(username: "marek", api_token: "token-1") }
  let(:opponent) { User.create!(username: "ania", api_token: "token-2") }

  it "broadcasts personalized game state to each player" do
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call
    Games::StartService.new(game: game).call

    allow(ActionCable.server).to receive(:broadcast)

    described_class.call(game: game, event: described_class::EVENT_GAME_UPDATED)

    expect(ActionCable.server).to have_received(:broadcast).with(
      "game:#{game.id}:user:#{user.id}",
      hash_including(
        event: "game.updated",
        game: hash_including(
          players: include(hash_including(id: user.id, rack: an_instance_of(Array)))
        )
      )
    )
    expect(ActionCable.server).to have_received(:broadcast).with(
      "game:#{game.id}:user:#{opponent.id}",
      hash_including(
        game: hash_including(
          players: include(hash_including(id: opponent.id, rack: an_instance_of(Array)))
        )
      )
    )
  end

  it "does not include opponent rack in a player's payload" do
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call
    Games::StartService.new(game: game).call

    payloads = []
    allow(ActionCable.server).to receive(:broadcast) do |stream, payload|
      payloads << payload if stream == "game:#{game.id}:user:#{user.id}"
    end

    described_class.call(game: game, event: described_class::EVENT_GAME_UPDATED)

    opponent_payload = payloads.first[:game][:players].find { |player| player[:id] == opponent.id }
    expect(opponent_payload).not_to have_key(:rack)
  end
end
