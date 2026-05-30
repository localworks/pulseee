class Question < ApplicationRecord
  has_many :survey_questions, dependent: :restrict_with_error

  before_destroy :prevent_destroy

  validates :body, presence: true

  private

  def prevent_destroy
    errors.add(:base, "標準設問は削除できません")
    throw :abort
  end
end
