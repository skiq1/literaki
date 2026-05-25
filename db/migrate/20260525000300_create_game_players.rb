class CreateGamePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :game_players do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :score, null: false, default: 0
      t.json :rack, null: false, default: []
      t.integer :position, null: false
      t.integer :passed_turns_count, null: false, default: 0

      t.timestamps
    end

    add_index :game_players, %i[game_id user_id], unique: true
  end
end
