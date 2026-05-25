class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :status, null: false, default: "waiting"
      t.references :current_turn_user, foreign_key: { to_table: :users }
      t.references :winner, foreign_key: { to_table: :users }
      t.json :board, null: false, default: {}
      t.json :bag, null: false, default: []
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :games, :status
  end
end
