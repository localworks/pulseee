class SurveyQuestion < ApplicationRecord
  belongs_to :survey
  belongs_to :question
  has_many :score_answers, dependent: :restrict_with_error

  validates :body, presence: true
  validates :order_index, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :question_id, uniqueness: { scope: :survey_id }
  validates :order_index, uniqueness: { scope: :survey_id }

  scope :ordered, -> { order(:order_index) }
end
