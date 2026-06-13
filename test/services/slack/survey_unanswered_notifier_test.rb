require "test_helper"

class Slack::SurveyUnansweredNotifierTest < ActiveSupport::TestCase
  setup do
    Question.ensure_standard_questions!
  end

  test "posts unanswered users to configured webhook" do
    survey = Survey.create!(title: "通知テスト", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)
    users = [
      User.create!(name: "未回答A", email: "first@example.com", survey_subject: true),
      User.create!(name: "未回答B", email: "second@example.com", survey_subject: true)
    ]
    http_client = FakeHttpClient.success

    assert Slack::SurveyUnansweredNotifier.call(
      survey: survey,
      users: users,
      webhook_url: "https://example.com/slack-webhook",
      http_client: http_client
    )

    uri, body, headers = http_client.requests.first
    payload = JSON.parse(body)

    assert_equal "https://example.com/slack-webhook", uri.to_s
    assert_equal "application/json", headers.fetch("Content-Type")
    assert_equal "サーベイ未回答者: 2名", payload.fetch("text")
    assert_includes payload.dig("blocks", 0, "text", "text"), "*通知テスト*"
    assert_includes payload.dig("blocks", 0, "text", "text"), "- 未回答A（first@example.com）"
    assert_includes payload.dig("blocks", 0, "text", "text"), "- 未回答B（second@example.com）"
  end

  test "raises when webhook is not configured" do
    survey = Survey.create!(title: "通知テスト", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)

    assert_raises Slack::SurveyUnansweredNotifier::ConfigurationError do
      Slack::SurveyUnansweredNotifier.call(survey: survey, users: [], webhook_url: nil)
    end
  end

  test "raises when slack returns non success response" do
    survey = Survey.create!(title: "通知テスト", status: :active, start_at: 1.hour.ago, end_at: 1.hour.from_now)

    assert_raises Slack::SurveyUnansweredNotifier::DeliveryError do
      Slack::SurveyUnansweredNotifier.call(
        survey: survey,
        users: [],
        webhook_url: "https://example.com/slack-webhook",
        http_client: FakeHttpClient.failure
      )
    end
  end

  class FakeHttpClient
    attr_reader :requests

    def self.success
      new(Net::HTTPSuccess.new("1.1", "200", "OK"))
    end

    def self.failure
      new(Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error"))
    end

    def initialize(response)
      @response = response
      @requests = []
    end

    def post(uri, body, headers)
      requests << [ uri, body, headers ]

      @response
    end
  end
end
