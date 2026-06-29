namespace :survey do
  desc "Aggregate weekly team scores for the previous week"
  task aggregate_weekly_scores: :environment do
    Surveys::AggregateWeeklyTeamScores.call
  end
end
