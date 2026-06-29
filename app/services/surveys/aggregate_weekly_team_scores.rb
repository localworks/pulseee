module Surveys
  class AggregateWeeklyTeamScores
    UNKNOWN_GROUP_NAME = "未設定".freeze

    def self.call(now: Time.current)
      new(now: now).call
    end

    def initialize(now:)
      @now = now
    end

    def call
      surveys.each do |survey|
        aggregate_survey(survey)
      end
    end

    private

    attr_reader :now

    def aggregate_survey(survey)
      rows_by_group(survey).each_value do |rows|
        response_count = rows.map { |row| row.fetch("submit_token") }.uniq.size
        next if response_count.zero?

        TeamWeeklyScore.upsert(
          {
            survey_id: survey.id,
            week_start_on: survey.start_at.to_date,
            week_end_on: survey.end_at.to_date,
            group_name: rows.first.fetch("group_name").presence || UNKNOWN_GROUP_NAME,
            overall_average: average(rows.map { |row| row.fetch("score") }),
            response_count: response_count,
            question_averages: question_averages(rows),
            created_at: Time.current,
            updated_at: Time.current
          },
          unique_by: [ :survey_id, :group_name ]
        )
      end
    end

    def rows_by_group(survey)
      ScoreAnswer
        .joins(survey_question: :survey)
        .joins("left join answer_group_snapshots on answer_group_snapshots.submit_token = score_answers.submit_token")
        .where(survey_questions: { survey_id: survey.id })
        .pluck(
          Arel.sql("coalesce(answer_group_snapshots.group_name, '#{UNKNOWN_GROUP_NAME}')"),
          "score_answers.submit_token",
          "survey_questions.id",
          "survey_questions.order_index",
          "survey_questions.body",
          "score_answers.score"
        )
        .map { |group_name, submit_token, survey_question_id, order_index, body, score|
          {
            "group_name" => group_name,
            "submit_token" => submit_token,
            "survey_question_id" => survey_question_id,
            "order_index" => order_index,
            "body" => body,
            "score" => score
          }
        }
        .group_by { |row| row.fetch("group_name") }
    end

    def surveys
      Survey
        .active
        .where("end_at <= ?", now)
        .where("exists (select 1 from survey_questions where survey_questions.survey_id = surveys.id)")
    end

    def question_averages(rows)
      rows
        .group_by { |row| row.fetch("order_index") }
        .sort_by { |order_index, _question_rows| order_index }
        .map { |order_index, question_rows|
          [
            order_index.to_s,
            {
              order_index: question_rows.first.fetch("order_index"),
              body: question_rows.first.fetch("body"),
              average: average(question_rows.map { |row| row.fetch("score") })
            }
          ]
        }
        .to_h
    end

    def average(scores)
      (scores.sum.to_d / scores.size).round(2)
    end
  end
end
