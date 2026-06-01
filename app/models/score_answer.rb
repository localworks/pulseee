class ScoreAnswer < ApplicationRecord
  belongs_to :survey_question

  before_update :prevent_mutation
  before_destroy :prevent_mutation

  validates :submit_token, presence: true
  validates :score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :survey_question_id, uniqueness: { scope: :submit_token }

  private

  def prevent_mutation
    errors.add(:base, "回答スコアは変更できません")
    throw :abort
  end
end
