module Admin
  class SurveyResultsController < ApplicationController
    before_action :require_system_admin

    def show
      survey = Survey.find(params[:survey_id])
      csv = SurveyResultCsvExporter.new(survey).generate

      send_data csv,
                filename: "survey-#{survey.id}-results.csv",
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
    end

    private

    def require_system_admin
      return if current_user&.system_admin?

      redirect_to root_path, alert: current_user ? "管理者権限が必要です" : "ログインしてください"
    end
  end
end
