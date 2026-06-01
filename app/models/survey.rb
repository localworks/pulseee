class Survey < ApplicationRecord
  enum :status, { draft: "draft", active: "active" }, validate: true

  has_many :survey_questions, -> { order(:order_index) }, dependent: :destroy
  has_many :survey_assignments, dependent: :destroy
  has_many :score_answers, through: :survey_questions

  validates :title, :start_at, :end_at, presence: true
  validate :end_at_after_start_at
  validate :standard_questions_exist, on: :create

  after_create :copy_standard_questions
  after_save :create_assignments_when_first_active
  before_destroy :ensure_deletable

  scope :currently_active, -> {
    active.where("start_at <= ? and end_at > ?", Time.current, Time.current)
  }

  def currently_active?
    active? && start_at <= Time.current && end_at > Time.current
  end

  def deletable?
    draft? && !score_answers.exists?
  end

  private

  def end_at_after_start_at
    return if start_at.blank? || end_at.blank?

    errors.add(:end_at, "は開始日時より後にしてください") unless end_at > start_at
  end

  def standard_questions_exist
    errors.add(:base, "標準設問を1件以上登録してください") if Question.none?
  end

  def copy_standard_questions
    Question.order(:id).find_each.with_index(1) do |question, index|
      survey_questions.create!(
        question: question,
        body: question.body,
        order_index: index
      )
    end
  end

  def create_assignments_when_first_active
    return unless active?
    return if survey_assignments.exists?

    User.where(survey_subject: true).find_each do |user|
      survey_assignments.create!(user: user, state: :pending)
    end
  end

  def ensure_deletable
    return if deletable?

    errors.add(:base, "削除できるのは回答がない下書きサーベイだけです")
    throw :abort
  end
end
