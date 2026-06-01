class CreateMvpSurveyTables < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.boolean :survey_subject, null: false, default: false

      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :roles do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :roles, :name, unique: true

    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
    add_index :user_roles, [ :user_id, :role_id ], unique: true

    create_table :questions do |t|
      t.string :body, null: false

      t.timestamps
    end

    create_table :surveys do |t|
      t.string :title, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false

      t.timestamps
    end
    add_index :surveys, :status
    add_check_constraint :surveys, "status in ('draft', 'active')", name: "chk_surveys_status"
    add_check_constraint :surveys, "end_at > start_at", name: "chk_surveys_period"

    create_table :survey_questions do |t|
      t.references :survey, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :body, null: false
      t.integer :order_index, null: false

      t.timestamps
    end
    add_index :survey_questions, [ :survey_id, :order_index ], unique: true
    add_index :survey_questions, [ :survey_id, :question_id ], unique: true

    create_table :survey_assignments do |t|
      t.references :survey, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :state, null: false, default: "pending"
      t.datetime :submitted_at

      t.timestamps
    end
    add_index :survey_assignments, [ :survey_id, :user_id ], unique: true
    add_index :survey_assignments, :state
    add_check_constraint :survey_assignments, "state in ('pending', 'submitted')", name: "chk_survey_assignments_state"

    create_table :score_answers, id: :primary_key do |t|
      t.string :submit_token, null: false
      t.references :survey_question, null: false, foreign_key: true
      t.integer :score, null: false
    end
    add_index :score_answers, [ :submit_token, :survey_question_id ], unique: true
    add_check_constraint :score_answers, "score between 1 and 5", name: "chk_score_answers_score"
  end
end
