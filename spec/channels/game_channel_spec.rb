require "rails_helper"

RSpec.describe GameChannel, type: :channel do
  let(:user) { User.create!(username: "marek", api_token: "token-1") }
  let(:opponent) { User.create!(username: "ania", api_token: "token-2") }

  it "subscribes game player to their private game stream" do
    game = Games::CreateService.new(user: user).call.value

    stub_connection current_user: user
    subscribe game_id: game.id

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("game:#{game.id}:user:#{user.id}")
  end

  it "rejects user who is not a game player" do
    game = Games::CreateService.new(user: user).call.value

    stub_connection current_user: opponent
    subscribe game_id: game.id

    expect(subscription).to be_rejected
  end

  it "rejects missing game" do
    stub_connection current_user: user
    subscribe game_id: 123_456

    expect(subscription).to be_rejected
  end
end
