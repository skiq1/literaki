require "rails_helper"

RSpec.describe "Games API", type: :request do
  let(:user) { User.create!(username: "marek", api_token: "token-1") }
  let(:opponent) { User.create!(username: "ania", api_token: "token-2") }

  it "allows authenticated user to create a game" do
    post "/api/v1/games", headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    expect(json["status"]).to eq("waiting")
    expect(json["time_limit_enabled"]).to be(true)
    expect(json["players"].size).to eq(1)
  end

  it "allows authenticated user to create a game without time limit" do
    post "/api/v1/games", params: { time_limit_enabled: false }, headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    expect(json["time_limit_enabled"]).to be(false)
    expect(json["current_turn_deadline_at"]).to be_nil
    expect(json["players"].first["remaining_time_ms"]).to be_nil
  end

  it "allows user to join waiting game" do
    game = Games::CreateService.new(user: user).call.value

    post "/api/v1/games/#{game.id}/join", headers: auth_headers(opponent)

    expect(response).to have_http_status(:ok)
    expect(json["players"].size).to eq(2)
  end

  it "does not allow joining active game" do
    game = started_game
    third_user = User.create!(username: "ola", api_token: "token-3")

    post "/api/v1/games/#{game.id}/join", headers: auth_headers(third_user)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "does not allow more than two players" do
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call
    third_user = User.create!(username: "ola", api_token: "token-3")

    post "/api/v1/games/#{game.id}/join", headers: auth_headers(third_user)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to include("Game already has two players")
  end

  it "requires two players to start game" do
    game = Games::CreateService.new(user: user).call.value

    post "/api/v1/games/#{game.id}/start", headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to include("Game requires exactly two players")
  end

  it "starts game and deals racks" do
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call

    post "/api/v1/games/#{game.id}/start", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(json["status"]).to eq("active")
    expect(json["current_turn_user_id"]).to eq(user.id)
    expect(json["turn_started_at"]).to be_present
    expect(json["current_turn_deadline_at"]).to be_present
    expect(json["players"].first["rack"].size).to eq(7)
    expect(json["players"].first["remaining_time_ms"]).to be <= Games::ClockService::DEFAULT_TIME_LIMIT_MS
    expect(json["players"].second).not_to have_key("rack")
  end

  def started_game
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call
    Games::StartService.new(game: game).call.value
  end
end
