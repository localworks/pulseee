require "test_helper"

class SurveyResponseTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    7.times { |index| Question.create!(body: "設問#{index + 1}") }
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "logged in user sees home" do
    user = User.create!(name: "利用者", email: "user@example.com")

    login_as(user)

    get root_path

    assert_response :success
    assert_select "h2", text: "利用者さん"
  end

  test "pending user can answer active survey once" do
    user = User.create!(name: "対象者", email: "subject@example.com", survey_subject: true)
    survey = Survey.create!(title: "今週のサーベイ", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
    assignment = survey.survey_assignments.find_by!(user: user)

    login_as(user)
    get root_path
    assert_select "a", text: "回答する"
    get new_survey_assignment_response_path(assignment)
    assert_response :success
    assert_select "input.score-range[type=range][min='1'][max='10']", count: 7
    assert_select ".score-scale span", count: 70
    assert_select ".score-value strong", text: "未選択", count: 7

    assert_difference -> { ScoreAnswer.count }, 7 do
      post survey_assignment_response_path(assignment), params: { answers: answers_for(survey, 4) }
    end
    follow_redirect!

    assert_select ".flash.notice", text: "回答を送信しました"
    assert_select "h3", text: "回答が必要なサーベイはありません"

    assert_no_difference -> { ScoreAnswer.count } do
      post survey_assignment_response_path(assignment), params: { answers: answers_for(survey, 5) }
    end
    follow_redirect!
    assert_select ".flash.alert", text: "回答が必要なサーベイはありません"

    assert_no_difference -> { ScoreAnswer.count } do
      get new_survey_assignment_response_path(assignment)
    end
    follow_redirect!
    assert_select ".flash.alert", text: "回答が必要なサーベイはありません"
  end

  test "expired and out of target surveys are not shown" do
    user = User.create!(name: "対象者", email: "hidden@example.com", survey_subject: true)
    expired = Survey.create!(title: "期限切れ", status: :active, start_at: 2.hours.ago, end_at: 1.hour.ago)
    assignment = expired.survey_assignments.find_by!(user: user)
    other = User.create!(name: "対象外", email: "outside@example.com", survey_subject: false)

    login_as(user)
    get root_path
    assert_select "h3", text: "回答が必要なサーベイはありません"
    get new_survey_assignment_response_path(assignment)
    follow_redirect!
    assert_select ".flash.alert", text: "回答が必要なサーベイはありません"

    user.update!(survey_subject: false)
    Survey.create!(title: "対象外には出ない", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
    login_as(other)
    get root_path
    assert_select "h3", text: "回答が必要なサーベイはありません"
  end

  test "partial answers keep input and do not save" do
    user = User.create!(name: "対象者", email: "partial@example.com", survey_subject: true)
    survey = Survey.create!(title: "未回答チェック", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
    assignment = survey.survey_assignments.find_by!(user: user)
    answers = answers_for(survey, 3)
    answers.delete(survey.survey_questions.first.id.to_s)

    login_as(user)

    assert_no_difference -> { ScoreAnswer.count } do
      post survey_assignment_response_path(assignment), params: { answers: answers }
    end

    assert_response :unprocessable_content
    assert_select ".flash.alert", text: "すべての設問に回答してください"
    assert_select "input[type=hidden][name^='answers'][value='3']", count: 6
  end

  test "missing answers are rejected without server error" do
    user = User.create!(name: "対象者", email: "missing@example.com", survey_subject: true)
    survey = Survey.create!(title: "未送信チェック", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
    assignment = survey.survey_assignments.find_by!(user: user)

    login_as(user)

    assert_no_difference -> { ScoreAnswer.count } do
      post survey_assignment_response_path(assignment)
    end

    assert_response :unprocessable_content
    assert_select ".flash.alert", text: "すべての設問に回答してください"
  end

  test "unexpected answer keys are ignored" do
    user = User.create!(name: "対象者", email: "extra@example.com", survey_subject: true)
    survey = Survey.create!(title: "余計なキー", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
    assignment = survey.survey_assignments.find_by!(user: user)
    answers = answers_for(survey, 4).merge("not_a_question" => "5", "999999" => "5")

    login_as(user)

    assert_difference -> { ScoreAnswer.count }, 7 do
      post survey_assignment_response_path(assignment), params: { answers: answers }
    end

    assert_redirected_to root_path
  end

  private

  def login_as(user)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-#{user.email}",
      info: { email: user.email, name: user.name }
    )
    post "/auth/google_oauth2"
    follow_redirect! while response.redirect?
  end

  def answers_for(survey, score)
    survey.survey_questions.reload.index_with { score }.transform_keys { |question| question.id.to_s }
  end
end
