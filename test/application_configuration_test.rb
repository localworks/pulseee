require "test_helper"

class ApplicationConfigurationTest < ActiveSupport::TestCase
  test "uses Tokyo time zone" do
    assert_equal "Tokyo", Time.zone.name
  end
end
