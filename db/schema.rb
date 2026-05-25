# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_25_000500) do
  create_table "game_players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "passed_turns_count", default: 0, null: false
    t.integer "position", null: false
    t.json "rack", default: [], null: false
    t.integer "score", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["game_id", "user_id"], name: "index_game_players_on_game_id_and_user_id", unique: true
    t.index ["game_id"], name: "index_game_players_on_game_id"
    t.index ["user_id"], name: "index_game_players_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.json "bag", default: [], null: false
    t.json "board", default: {}, null: false
    t.datetime "created_at", null: false
    t.integer "current_turn_user_id"
    t.datetime "finished_at"
    t.datetime "started_at"
    t.string "status", default: "waiting", null: false
    t.datetime "updated_at", null: false
    t.integer "winner_id"
    t.index ["current_turn_user_id"], name: "index_games_on_current_turn_user_id"
    t.index ["status"], name: "index_games_on_status"
    t.index ["winner_id"], name: "index_games_on_winner_id"
  end

  create_table "moves", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.string "move_type", null: false
    t.integer "score", default: 0, null: false
    t.json "tiles", default: [], null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.json "words", default: [], null: false
    t.index ["game_id"], name: "index_moves_on_game_id"
    t.index ["user_id"], name: "index_moves_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token", null: false
    t.datetime "created_at", null: false
    t.integer "games_played", default: 0, null: false
    t.integer "games_won", default: 0, null: false
    t.integer "total_score", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
  end

  create_table "words", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "language", default: "pl", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["value", "language"], name: "index_words_on_value_and_language", unique: true
  end

  add_foreign_key "game_players", "games"
  add_foreign_key "game_players", "users"
  add_foreign_key "games", "users", column: "current_turn_user_id"
  add_foreign_key "games", "users", column: "winner_id"
  add_foreign_key "moves", "games"
  add_foreign_key "moves", "users"
end
