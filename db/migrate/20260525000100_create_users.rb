class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :api_token, null: false
      t.integer :games_played, null: false, default: 0
      t.integer :games_won, null: false, default: 0
      t.integer :total_score, null: false, default: 0

      t.timestamps
    end

    add_index :users, :api_token, unique: true
  end
end
