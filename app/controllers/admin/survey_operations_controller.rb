class Admin::SurveyOperationsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_system_admin!

  def show
    @current_week_survey = Surveys::CreateCurrentWeekSurvey.current_survey
    @current_active_survey = Survey.currently_active.order(:end_at).first
    @unanswered_count = @current_active_survey ? Surveys::UnansweredUsersQuery.call(survey: @current_active_survey).count : 0
    @slack_configured = Slack::SurveyUnansweredNotifier.configured?
  end

  def create_current_week_survey
    SurveyCreationJob.perform_later

    redirect_to admin_survey_operation_path, notice: "今週分サーベイ作成ジョブを登録しました"
  end

  def notify_unanswered_users
    survey = Survey.currently_active.order(:end_at).first
    unless survey
      redirect_to admin_survey_operation_path, alert: "通知対象の有効なサーベイがありません"
      return
    end

    unless Slack::SurveyUnansweredNotifier.configured?
      redirect_to admin_survey_operation_path, alert: "Slack通知用の環境変数を設定してください"
      return
    end

    SurveyUnansweredNotificationJob.perform_later(survey.id)

    redirect_to admin_survey_operation_path, notice: "未回答者のSlack通知ジョブを登録しました"
  end

  private

  def authorize_system_admin!
    return if current_user&.system_admin?

    redirect_to root_path, alert: "管理者権限が必要です"
  end
end
