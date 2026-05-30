class SurveyResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assignment

  def new
    @answers = {}
  end

  def create
    @answers = answer_params.to_h

    if @assignment.submit_scores!(@answers)
      redirect_to root_path, notice: "回答を送信しました"
    else
      flash.now[:alert] = @assignment.errors.full_messages.first || "すべての設問に回答してください"
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_assignment
    @assignment = current_user.survey_assignments.find_by(id: params[:survey_assignment_id])

    return if @assignment&.answerable?

    redirect_to root_path, alert: "回答が必要なサーベイはありません"
  end

  def answer_params
    params.fetch(:answers, {}).permit!
  end
end
