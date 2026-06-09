require "rails_helper"

RSpec.describe "Moves API", type: :request do
  let(:user) { User.create!(username: "marek", api_token: "token-1") }
  let(:opponent) { User.create!(username: "ania", api_token: "token-2") }

  it "returns unauthorized without token" do
    game = started_game

    post "/api/v1/games/#{game.id}/moves", params: { move_type: "pass" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "allows only current turn player to move" do
    game = started_game

    post "/api/v1/games/#{game.id}/moves", params: { move_type: "pass" }, headers: auth_headers(opponent)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to include("It is not this user's turn")
  end

  it "creates pass move and changes turn" do
    game = started_game

    post "/api/v1/games/#{game.id}/moves", params: { move_type: "pass" }, headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    expect(json["move_type"]).to eq("pass")
    expect(game.reload.current_turn_user_id).to eq(opponent.id)
  end

  it "resign finishes game and sets winner" do
    game = started_game

    post "/api/v1/games/#{game.id}/moves", params: { move_type: "resign" }, headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    expect(game.reload.status).to eq("finished")
    expect(game.winner_id).to eq(opponent.id)
  end

  it "exchanges tiles" do
    game = started_game
    player = game.game_players.find_by!(user: user)
    player.update!(rack: %w[A E R K O T S])
    game.update!(bag: %w[Z W Y])

    post "/api/v1/games/#{game.id}/moves",
      params: { move_type: "exchange_tiles", tiles: %w[A E R] },
      headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    expect(json["tiles"]).to eq(%w[A E R])
    expect(player.reload.rack.size).to eq(7)
    expect(player.rack).not_to include("A", "E", "R")
  end

  it "places tiles and updates board, score, rack and turn" do
    Word.create!(value: "KOT", language: "pl")
    game = started_game
    player = game.game_players.find_by!(user: user)
    player.update!(rack: %w[K O T A E R S])
    game.update!(bag: %w[Z W Y])

    post "/api/v1/games/#{game.id}/moves",
      params: { move_type: "place_tiles", tiles: [ { letter: "K", x: 7, y: 7 }, { letter: "O", x: 8, y: 7 }, { letter: "T", x: 9, y: 7 } ] },
      headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    expect(json["score"]).to eq(5)
    expect(game.reload.board).to include("7,7" => "K", "8,7" => "O", "9,7" => "T")
    expect(player.reload.score).to eq(5)
    expect(player.rack.size).to eq(7)
    expect(game.current_turn_user_id).to eq(opponent.id)
  end

  it "rejects word missing from dictionary" do
    game = started_game
    player = game.game_players.find_by!(user: user)
    player.update!(rack: %w[K O A E R S T])

    post "/api/v1/games/#{game.id}/moves",
      params: { move_type: "place_tiles", tiles: [ { letter: "K", x: 7, y: 7 }, { letter: "O", x: 8, y: 7 } ] },
      headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to include("KO is not in dictionary")
    expect(game.reload.board).to eq({})
    expect(player.reload.rack).to eq(%w[K O A E R S T])
  end

  it "rejects tile outside rack" do
    game = started_game
    game.game_players.find_by!(user: user).update!(rack: %w[A E R K O T S])

    post "/api/v1/games/#{game.id}/moves",
      params: { move_type: "place_tiles", tiles: [ { letter: "Z", x: 7, y: 7 } ] },
      headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to include("Rack does not include all requested tiles")
  end

  it "rejects occupied square" do
    game = started_game
    game.update!(board: { "7,7" => "A" })
    game.game_players.find_by!(user: user).update!(rack: %w[K O T A E R S])

    post "/api/v1/games/#{game.id}/moves",
      params: { move_type: "place_tiles", tiles: [ { letter: "K", x: 7, y: 7 } ] },
      headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to include("Tile position is already occupied")
  end

  it "rejects tile outside board" do
    game = started_game
    game.game_players.find_by!(user: user).update!(rack: %w[K O T A E R S])

    post "/api/v1/games/#{game.id}/moves",
      params: { move_type: "place_tiles", tiles: [ { letter: "K", x: 15, y: 7 } ] },
      headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to include("Tile is outside the board")
  end

  def started_game
    game = Games::CreateService.new(user: user).call.value
    Games::JoinService.new(game: game, user: opponent).call
    Games::StartService.new(game: game).call.value
  end
end
