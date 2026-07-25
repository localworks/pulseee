class SurveyResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assignment

  def new
    @answers = {}
    @free_text_answer = ""
  end

  def create
    @answers = answer_params.to_h
    @free_text_answer = free_text_answer_param

    if @assignment.submit_scores!(@answers, free_text: @free_text_answer)
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
    answers = params.fetch(:answers, ActionController::Parameters.new)
    answers = ActionController::Parameters.new(answers) unless answers.respond_to?(:permit)

    question_ids = @assignment.survey.survey_questions.pluck(:id).map(&:to_s)
    permitted_question_ids = question_ids.select { |id| id.match?(/\A\d+\z/) }

    answers.permit(*permitted_question_ids)
  end

  def free_text_answer_param
    params.permit(:free_text_answer).fetch(:free_text_answer, "")
  end
end
