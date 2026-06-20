require "test_helper"
require "fugit"
require "yaml"

class ApplicationConfigurationTest < ActiveSupport::TestCase
  test "uses Tokyo time zone" do
    assert_equal "Tokyo", Time.zone.name
  end

  test "schedules weekly survey operation cycle" do
    recurring_config = YAML.load_file(Rails.root.join("config/recurring.yml"))

    assert_recurring_job recurring_config,
                         "survey_creation",
                         "SurveyCreationJob",
                         "0 9 * * 4"
    assert_recurring_job recurring_config,
                         "survey_unanswered_notification_thursday",
                         "SurveyUnansweredNotificationJob",
                         "0 18 * * 4"
    assert_recurring_job recurring_config,
                         "survey_unanswered_notification_friday",
                         "SurveyUnansweredNotificationJob",
                         "0 12 * * 5"
    assert_recurring_job recurring_config,
                         "survey_weekly_aggregation",
                         "SurveyWeeklyAggregationJob",
                         "0 9 * * 1"
  end

  private

  def assert_recurring_job(config, key, job_class, cron)
    schedule = config.dig("production", key)

    assert_equal job_class, schedule.fetch("class")
    assert_equal "default", schedule.fetch("queue")
    assert_equal cron, Fugit.parse(schedule.fetch("schedule")).original
  end
end
