class UpdateScoreAnswersScoreConstraintToTen < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :score_answers, name: "chk_score_answers_score", if_exists: true
    add_check_constraint :score_answers, "score between 1 and 10", name: "chk_score_answers_score"
  end

  def down
    remove_check_constraint :score_answers, name: "chk_score_answers_score", if_exists: true
    add_check_constraint :score_answers, "score between 1 and 5", name: "chk_score_answers_score"
  end
end
