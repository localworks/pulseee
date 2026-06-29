module Admin
  class TeamWeeklyScoresController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_score_viewer!

    def index
      @team_weekly_scores = TeamWeeklyScore.includes(:survey).recent
      @group_names = @team_weekly_scores.map(&:group_name).uniq
      @question_labels = question_labels
      @weeks = @team_weekly_scores.map(&:week_start_on).uniq.sort
      @latest_week = @weeks.last
      @previous_week = @weeks[-2]
      @scores_by_group = @team_weekly_scores.group_by(&:group_name)
      @latest_scores = scores_for_week(@latest_week)
      @previous_scores = scores_for_week(@previous_week)
      @overall_points = overall_points
      @overall_latest_average = average(@latest_scores.map(&:overall_average))
      @overall_previous_average = average(@previous_scores.map(&:overall_average))
      @overall_delta = delta(@overall_latest_average, @overall_previous_average)
      @latest_response_count = @latest_scores.sum(&:response_count)
      @team_cards = team_cards
    end

    private

    def authorize_score_viewer!
      return if current_user&.score_viewer?

      redirect_to root_path, alert: "閲覧権限が必要です"
    end

    def question_labels
      @team_weekly_scores.each_with_object({}) do |score, labels|
        score.question_averages.each do |order_index, payload|
          labels[order_index] ||= "Q#{payload.fetch("order_index")}"
        end
      end
    end

    def scores_for_week(week_start_on)
      return [] unless week_start_on

      @team_weekly_scores.select { |score| score.week_start_on == week_start_on }
    end

    def overall_points
      @weeks.map do |week_start_on|
        scores = scores_for_week(week_start_on)
        {
          label: I18n.l(week_start_on, format: :short),
          value: average(scores.map(&:overall_average))
        }
      end
    end

    def team_cards
      @scores_by_group.map do |group_name, scores|
        latest = scores.max_by(&:week_start_on)
        previous = scores.sort_by(&:week_start_on)[-2]

        {
          group_name: group_name,
          latest: latest,
          delta: delta(latest&.overall_average, previous&.overall_average),
          points: scores.sort_by(&:week_start_on).map { |score|
            {
              label: I18n.l(score.week_start_on, format: :short),
              value: score.overall_average
            }
          },
          question_averages: latest&.question_averages || {}
        }
      end.sort_by { |card| card.fetch(:group_name) }
    end

    def average(values)
      values = values.compact
      return nil if values.empty?

      (values.sum.to_d / values.size).round(2)
    end

    def delta(current, previous)
      return nil unless current && previous

      (current.to_d - previous.to_d).round(2)
    end
  end
end
