require "test_helper"

class Surveys::AggregateWeeklyTeamScoresTest < ActiveSupport::TestCase
  setup do
    Question.ensure_standard_questions!
  end

  test "creates team weekly scores for previous week by group" do
    development = Group.create!(name: "開発")
    sales = Group.create!(name: "営業")
    dev_user = User.create!(name: "開発者", email: "dev@example.com", survey_subject: true, group: development)
    sales_user = User.create!(name: "営業", email: "sales@example.com", survey_subject: true, group: sales)
    survey = Survey.create!(
      title: "前週サーベイ",
      status: :active,
      start_at: Time.zone.local(2026, 6, 11, 0, 0),
      end_at: Time.zone.local(2026, 6, 13, 0, 0)
    )

    travel_to Time.zone.local(2026, 6, 12, 12, 0) do
      survey.survey_assignments.find_by!(user: dev_user).submit_scores!(answers_for(survey, [ 5, 4, 3, 2, 1 ]))
      survey.survey_assignments.find_by!(user: sales_user).submit_scores!(answers_for(survey, [ 3, 3, 3, 3, 3 ]))
    end

    travel_to Time.zone.local(2026, 6, 15, 8, 0) do
      assert_difference("TeamWeeklyScore.count", 2) do
        Surveys::AggregateWeeklyTeamScores.call
      end
    end

    dev_score = TeamWeeklyScore.find_by!(group_name: "開発")
    assert_equal survey, dev_score.survey
    assert_equal Date.new(2026, 6, 8), dev_score.week_start_on
    assert_equal Date.new(2026, 6, 14), dev_score.week_end_on
    assert_equal 1, dev_score.response_count
    assert_equal BigDecimal("3.0"), dev_score.overall_average
    assert_equal BigDecimal("5.0"), BigDecimal(dev_score.question_averages.values.first.fetch("average").to_s)

    sales_score = TeamWeeklyScore.find_by!(group_name: "営業")
    assert_equal BigDecimal("3.0"), sales_score.overall_average
  end

  test "updates existing weekly score when rerun" do
    group = Group.create!(name: "開発")
    user = User.create!(name: "開発者", email: "rerun@example.com", survey_subject: true, group: group)
    survey = Survey.create!(
      title: "前週サーベイ",
      status: :active,
      start_at: Time.zone.local(2026, 6, 11, 0, 0),
      end_at: Time.zone.local(2026, 6, 13, 0, 0)
    )
    travel_to Time.zone.local(2026, 6, 12, 12, 0) do
      survey.survey_assignments.find_by!(user: user).submit_scores!(answers_for(survey, [ 4, 4, 4, 4, 4 ]))
    end

    travel_to Time.zone.local(2026, 6, 15, 8, 0) do
      Surveys::AggregateWeeklyTeamScores.call

      assert_no_difference("TeamWeeklyScore.count") do
        Surveys::AggregateWeeklyTeamScores.call
      end
    end
  end

  test "ignores surveys outside previous week" do
    user = User.create!(name: "対象者", email: "outside-week@example.com", survey_subject: true)
    survey = Survey.create!(
      title: "今週サーベイ",
      status: :active,
      start_at: Time.zone.local(2026, 6, 15, 0, 0),
      end_at: Time.zone.local(2026, 6, 17, 0, 0)
    )
    travel_to Time.zone.local(2026, 6, 16, 12, 0) do
      survey.survey_assignments.find_by!(user: user).submit_scores!(answers_for(survey, [ 4, 4, 4, 4, 4 ]))
    end

    travel_to Time.zone.local(2026, 6, 15, 8, 0) do
      assert_no_difference("TeamWeeklyScore.count") do
        Surveys::AggregateWeeklyTeamScores.call
      end
    end
  end

  private

  def answers_for(survey, scores)
    survey.survey_questions.ordered.zip(scores).to_h.transform_keys(&:id)
  end
end
