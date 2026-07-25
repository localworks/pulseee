class FreeTextAnswer < ApplicationRecord
  MAX_LENGTH = 2_000

  belongs_to :survey

  before_validation :normalize_body
  before_update :prevent_mutation
  before_destroy :prevent_mutation

  validates :submit_token, presence: true, uniqueness: true
  validates :body, presence: true, length: { maximum: MAX_LENGTH }

  private

  def normalize_body
    self.body = body.to_s.strip
  end

  def prevent_mutation
    errors.add(:base, "自由記述回答は変更できません")
    throw :abort
  end
end
