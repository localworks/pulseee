class WeeklyScoreNote < ApplicationRecord
  MAX_LENGTH = 1_000

  belongs_to :author, class_name: "User"

  validates :week_start_on, presence: true, uniqueness: true
  validates :body, presence: true, length: { maximum: MAX_LENGTH }
end
