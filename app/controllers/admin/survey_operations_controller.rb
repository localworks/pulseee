class Admin::SurveyOperationsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_system_admin!

  def show
    @current_week_survey = Surveys::CreateCurrentWeekSurvey.current_survey
  end

  def create_current_week_survey
    SurveyCreationJob.perform_later

    redirect_to admin_survey_operation_path, notice: "今週分サーベイ作成ジョブを登録しました"
  end

  private

  def authorize_system_admin!
    return if current_user&.system_admin?

    redirect_to root_path, alert: "管理者権限が必要です"
  end
end
