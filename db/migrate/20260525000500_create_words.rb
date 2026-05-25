class CreateWords < ActiveRecord::Migration[8.1]
  def change
    create_table :words do |t|
      t.string :value, null: false
      t.string :language, null: false, default: "pl"

      t.timestamps
    end

    add_index :words, %i[value language], unique: true
  end
end
