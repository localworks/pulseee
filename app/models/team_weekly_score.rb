class TeamWeeklyScore < ApplicationRecord
  belongs_to :survey

  validates :week_start_on, :week_end_on, :group_name, :overall_average, :response_count, :question_averages, presence: true
  validates :group_name, uniqueness: { scope: :survey_id }
  validates :response_count, numericality: { only_integer: true, greater_than: 0 }
  validates :overall_average, numericality: {
    greater_than_or_equal_to: ScoreAnswer::MIN_SCORE,
    less_than_or_equal_to: ScoreAnswer::MAX_SCORE
  }

  scope :recent, -> { order(week_start_on: :desc, group_name: :asc) }
  scope :chronological, -> { order(week_start_on: :asc, group_name: :asc) }
end
