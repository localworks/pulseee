class SurveyWeeklyAggregationJob < ApplicationJob
  queue_as :default

  def perform
    Surveys::AggregateWeeklyTeamScores.call
  end
end
