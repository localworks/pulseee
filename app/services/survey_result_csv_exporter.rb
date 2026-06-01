require "csv"

class SurveyResultCsvExporter
  UTF_8_BOM = "\uFEFF"

  def initialize(survey)
    @survey = survey
  end

  def generate
    csv_body = CSV.generate(headers: true) do |csv|
      csv << headers

      anonymous_responses.each do |(_, answers)|
        answer_by_question_id = answers.index_by(&:survey_question_id)

        csv << [
          survey.id,
          survey.title,
          *questions.map { |question| answer_by_question_id[question.id]&.score }
        ]
      end
    end

    "#{UTF_8_BOM}#{csv_body}"
  end

  private

  attr_reader :survey

  def headers
    [
      "サーベイID",
      "サーベイ名",
      *questions.map { |question| "Q#{question.order_index}" }
    ]
  end

  def questions
    @questions ||= survey.survey_questions.ordered.to_a
  end

  def anonymous_responses
    @anonymous_responses ||= survey
      .score_answers
      .includes(:survey_question)
      .group_by(&:submit_token)
      .sort_by { |submit_token, _| submit_token }
  end
end
