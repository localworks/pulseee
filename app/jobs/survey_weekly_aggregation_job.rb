class SurveyWeeklyAggregationJob < ApplicationJob
  queue_as :default

  def perform
    export_csv
    Surveys::AggregateWeeklyTeamScores.call
  end

  private

  def export_csv
    survey = Survey.active.where("end_at <= ?", Time.current).order(end_at: :desc).first
    return unless survey

    SurveyResultCsvExporter.new(survey).generate
  end
end
