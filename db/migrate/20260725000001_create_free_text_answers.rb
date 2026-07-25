class CreateFreeTextAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :free_text_answers do |t|
      t.references :survey, null: false, foreign_key: true
      t.string :submit_token, null: false
      t.text :body, null: false
    end

    add_index :free_text_answers, :submit_token, unique: true
  end
end
