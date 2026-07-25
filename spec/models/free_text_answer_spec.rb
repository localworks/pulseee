require "rails_helper"

RSpec.describe "FreeTextAnswer" do
  before do
    create_standard_questions
    @survey = Survey.create!(
      title: "自由記述テスト",
      status: :draft,
      start_at: 1.hour.ago,
      end_at: 1.hour.from_now
    )
  end

  it "stores an anonymous body without identifying columns or timestamps" do
    answer = FreeTextAnswer.create!(
      survey: @survey,
      submit_token: "token-1",
      body: "  よかったこと  "
    )

    assert_equal "よかったこと", answer.body
    assert_not_includes FreeTextAnswer.column_names, "user_id"
    assert_not_includes FreeTextAnswer.column_names, "survey_assignment_id"
    assert_not_includes FreeTextAnswer.column_names, "created_at"
    assert_not_includes FreeTextAnswer.column_names, "updated_at"
  end

  it "requires a unique submit token and a body up to the maximum length" do
    FreeTextAnswer.create!(survey: @survey, submit_token: "token-1", body: "回答")

    assert_not FreeTextAnswer.new(survey: @survey, submit_token: "token-1", body: "別の回答").valid?
    assert FreeTextAnswer.new(
      survey: @survey,
      submit_token: "token-2",
      body: "あ" * FreeTextAnswer::MAX_LENGTH
    ).valid?
    assert_not FreeTextAnswer.new(
      survey: @survey,
      submit_token: "token-3",
      body: "あ" * (FreeTextAnswer::MAX_LENGTH + 1)
    ).valid?
  end

  it "is append only" do
    answer = FreeTextAnswer.create!(survey: @survey, submit_token: "token-1", body: "回答")
    answer.body = "変更"

    assert_not answer.save
    assert_not answer.destroy
  end
end
