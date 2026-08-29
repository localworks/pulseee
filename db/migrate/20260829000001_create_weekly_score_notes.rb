class CreateWeeklyScoreNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_score_notes do |t|
      t.date :week_start_on, null: false
      t.text :body, null: false
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :weekly_score_notes, :week_start_on, unique: true
  end
end
