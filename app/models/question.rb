class Question < ApplicationRecord
  STANDARD_BODIES = [
    "直近一週間に関して、あなたは自分がやりたいと思っている仕事ができていると思いますか？",
    "直近一週間に関して、あなたは良いパフォーマンス（行動や成果）を発揮できたと思いますか？",
    "直近一週間に関して、あなたは職場の人間関係が良好だったと思いますか？",
    "直近一週間に関して、あなたは十分な睡眠を取れていますか？",
    "直近1週間に関して、困ったことや壁にぶつかった際、上司に気兼ねなく相談・エスカレーションできる状態でしたか？"
  ].freeze

  has_many :survey_questions, dependent: :restrict_with_error

  before_destroy :prevent_destroy

  validates :body, presence: true

  def self.standard_ordered
    by_body = where(body: STANDARD_BODIES).index_by(&:body)

    STANDARD_BODIES.filter_map { |body| by_body[body] }
  end

  def self.standard_questions_ready?
    standard_ordered.size == STANDARD_BODIES.size
  end

  def self.ensure_standard_questions!
    STANDARD_BODIES.each do |body|
      find_or_create_by!(body: body)
    end
  end

  private

  def prevent_destroy
    errors.add(:base, "標準設問は削除できません")
    throw :abort
  end
end
