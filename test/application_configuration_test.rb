require "test_helper"
require "yaml"

class ApplicationConfigurationTest < ActiveSupport::TestCase
  test "uses Tokyo time zone" do
    assert_equal "Tokyo", Time.zone.name
  end

  test "does not schedule unanswered survey notification in app recurring jobs" do
    recurring_config = YAML.load_file(Rails.root.join("config/recurring.yml"))

    assert_nil recurring_config.dig("production", "survey_unanswered_notification")
  end
end
