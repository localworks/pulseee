require "test_helper"

class TeamWeeklyScoresTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    Question.ensure_standard_questions!
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "manager can view all team weekly scores" do
    manager = create_user_with_role("manager")
    create_weekly_score(group_name: "開発", overall_average: 4.2)
    create_weekly_score(group_name: "営業", overall_average: 3.4)

    login_as(manager)
    get admin_team_weekly_scores_path

    assert_response :success
    assert_select "h1", text: "チーム別スコア推移"
    assert_select "h2", text: "開発"
    assert_select "h2", text: "営業"
    assert_select ".team-score-line-chart svg"
    assert_select ".team-score-mini-chart svg", minimum: 2
    assert_select ".team-score-question-fill"
    assert_select "td strong", text: "4.20"
    assert_select "td strong", text: "3.40"
  end

  test "weekly score details are ordered newest first" do
    manager = create_user_with_role("manager")
    create_weekly_score(group_name: "開発", overall_average: 3.6, week_start_on: Date.new(2026, 6, 1))
    create_weekly_score(group_name: "開発", overall_average: 4.2, week_start_on: Date.new(2026, 6, 8))

    login_as(manager)
    get admin_team_weekly_scores_path

    assert_response :success
    assert_match(/Jun 08.*Jun 01/m, response.body)
  end

  test "system admin can navigate from home" do
    admin = create_user_with_role("system_admin")
    login_as(admin)

    get root_path

    assert_response :success
    assert_select "a[href='#{admin_team_weekly_scores_path}']", text: "スコア推移"
  end

  test "member cannot view team weekly scores" do
    member = User.create!(name: "一般", email: "member-score@example.com")
    login_as(member)

    get admin_team_weekly_scores_path
    follow_redirect!

    assert_select ".flash.alert", text: "閲覧権限が必要です"
  end

  private

  def create_user_with_role(role_name)
    role = Role.find_or_create_by!(name: role_name)
    User.create!(name: role_name, email: "#{role_name}@example.com").tap do |user|
      user.roles << role
    end
  end

  def create_weekly_score(group_name:, overall_average:, week_start_on: Date.new(2026, 6, 8))
    survey = Survey.create!(
      title: "#{group_name}サーベイ #{week_start_on}",
      status: :active,
      start_at: week_start_on.in_time_zone,
      end_at: (week_start_on + 4.days).in_time_zone
    )

    TeamWeeklyScore.create!(
      survey: survey,
      week_start_on: week_start_on,
      week_end_on: week_start_on + 6.days,
      group_name: group_name,
      overall_average: overall_average,
      response_count: 2,
      question_averages: {
        "1" => {
          order_index: 1,
          body: survey.survey_questions.ordered.first.body,
          average: overall_average
        }
      }
    )
  end

  def login_as(user)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-#{user.email}",
      info: { email: user.email, name: user.name }
    )
    post "/auth/google_oauth2"
    follow_redirect! while response.redirect?
  end
end
