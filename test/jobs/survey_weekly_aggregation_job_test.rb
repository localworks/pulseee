require "test_helper"

class SurveyWeeklyAggregationJobTest < ActiveJob::TestCase
  test "aggregates weekly team scores" do
    calls = 0
    original_call = Surveys::AggregateWeeklyTeamScores.method(:call)

    Surveys::AggregateWeeklyTeamScores.define_singleton_method(:call) do
      calls += 1
    end

    SurveyWeeklyAggregationJob.perform_now

    assert_equal 1, calls
  ensure
    Surveys::AggregateWeeklyTeamScores.define_singleton_method(:call, original_call) if original_call
  end
end
