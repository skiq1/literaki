class CreateMoves < ActiveRecord::Migration[8.1]
  def change
    create_table :moves do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :move_type, null: false
      t.json :tiles, null: false, default: []
      t.json :words, null: false, default: []
      t.integer :score, null: false, default: 0

      t.timestamps
    end
  end
end
