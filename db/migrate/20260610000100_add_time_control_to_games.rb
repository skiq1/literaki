class AddTimeControlToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :time_limit_enabled, :boolean, null: false, default: true
    add_column :games, :turn_started_at, :datetime
    add_column :game_players, :remaining_time_ms, :integer, null: false, default: 600_000
  end
end
