require "test_helper"
require "active_job/test_helper"

class AdminSurveyOperationsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    OmniAuth.config.test_mode = true
    Question.ensure_standard_questions!
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
    clear_enqueued_jobs
  end

  test "admin sees survey operation page" do
    admin = create_admin
    User.create!(name: "対象者", email: "subject@example.com", survey_subject: true)

    travel_to Time.zone.local(2026, 6, 10, 12, 0) do
      Survey.create!(title: "現在のサーベイ", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
      Surveys::CreateCurrentWeekSurvey.call
      login_as(admin)

      get admin_survey_operation_path

      assert_response :success
      assert_select "h1", text: "サーベイ運用"
      assert_select ".admin-operation-value", text: "2026-06-11"
      assert_select ".admin-operation-value", text: "現在のサーベイ"
      assert_select ".admin-operation-value", text: "1名"
    end
  end

  test "admin can navigate to survey operation from rails admin dashboard" do
    admin = create_admin
    login_as(admin)

    get rails_admin_path

    assert_response :success
    assert_select "a[href='/admin/survey_operation']", text: "サーベイ運用を開く"
  end

  test "non admins cannot access survey operation page" do
    member = User.create!(name: "一般", email: "member@example.com")
    login_as(member)

    get admin_survey_operation_path
    follow_redirect!

    assert_select ".flash.alert", text: "管理者権限が必要です"
  end

  test "admin can enqueue current week survey creation job" do
    admin = create_admin
    login_as(admin)

    assert_enqueued_with(job: SurveyCreationJob) do
      post create_current_week_survey_admin_survey_operation_path
    end

    assert_redirected_to admin_survey_operation_path
  end

  test "admin can enqueue unanswered notification job when slack is configured" do
    admin = create_admin
    survey = Survey.create!(title: "今週", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
    login_as(admin)

    with_slack_webhook("https://example.com/slack-webhook") do
      assert_enqueued_with(job: SurveyUnansweredNotificationJob, args: [ survey.id ]) do
        post notify_unanswered_users_admin_survey_operation_path
      end
    end

    assert_redirected_to admin_survey_operation_path
  end

  test "notification job is not enqueued without slack configuration" do
    admin = create_admin
    Survey.create!(title: "今週", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
    login_as(admin)

    with_slack_webhook(nil) do
      assert_no_enqueued_jobs do
        post notify_unanswered_users_admin_survey_operation_path
      end
    end

    assert_redirected_to admin_survey_operation_path
  end

  private

  def create_admin
    role = Role.find_or_create_by!(name: "system_admin")
    User.create!(name: "管理者", email: "admin@example.com").tap do |user|
      user.roles << role
    end
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

  def with_slack_webhook(value)
    previous = ENV["SLACK_SURVEY_WEBHOOK_URL"]
    ENV["SLACK_SURVEY_WEBHOOK_URL"] = value
    yield
  ensure
    ENV["SLACK_SURVEY_WEBHOOK_URL"] = previous
  end
end
