require "json"
require "net/http"
require "uri"

module Slack
  class SurveyUnansweredNotifier
    WEBHOOK_ENV_KEY = "SLACK_SURVEY_WEBHOOK_URL"
    DISPLAY_LIMIT = 30

    class ConfigurationError < StandardError; end
    class DeliveryError < StandardError; end

    def self.call(survey:, users:, webhook_url: ENV[WEBHOOK_ENV_KEY], http_client: Net::HTTP)
      new(survey: survey, users: users, webhook_url: webhook_url, http_client: http_client).call
    end

    def self.configured?
      ENV[WEBHOOK_ENV_KEY].present?
    end

    def initialize(survey:, users:, webhook_url:, http_client:)
      @survey = survey
      @users = users.to_a
      @webhook_url = webhook_url
      @http_client = http_client
    end

    def call
      raise ConfigurationError, "#{WEBHOOK_ENV_KEY} is not configured" if webhook_url.blank?

      response = http_client.post(
        URI.parse(webhook_url),
        JSON.generate(payload),
        "Content-Type" => "application/json"
      )

      raise DeliveryError, "Slack webhook returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      true
    end

    private

    attr_reader :survey, :users, :webhook_url, :http_client

    def payload
      {
        text: fallback_text,
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: message_text
            }
          }
        ]
      }
    end

    def fallback_text
      "サーベイ未回答者: #{users.size}名"
    end

    def message_text
      lines = [
        "*#{survey.title}*",
        "未回答者: #{users.size}名"
      ]

      return (lines + [ "未回答者はいません。" ]).join("\n") if users.empty?

      displayed_users = users.first(DISPLAY_LIMIT)
      user_lines = displayed_users.map { |user| "- #{user.name}（#{user.email}）" }
      remaining_count = users.size - displayed_users.size
      user_lines << "- ほか#{remaining_count}名" if remaining_count.positive?

      (lines + user_lines).join("\n")
    end
  end
end
