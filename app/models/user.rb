class User < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :survey_assignments, dependent: :restrict_with_error

  before_validation :normalize_email
  before_destroy :prevent_destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  def system_admin?
    roles.exists?(name: "system_admin")
  end

  def next_pending_survey_assignment
    survey_assignments.answerable.first
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def prevent_destroy
    errors.add(:base, "ユーザーは削除できません")
    throw :abort
  end
end
