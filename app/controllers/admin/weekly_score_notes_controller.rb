module Admin
  class WeeklyScoreNotesController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_system_admin!
    before_action :set_weekly_score_note, only: %i[update destroy]

    def create
      @weekly_score_note = current_user.weekly_score_notes.build(weekly_score_note_params)
      return unless completed_week?

      if @weekly_score_note.save
        redirect_to team_weekly_scores_path_for_note, notice: "週次メモを保存しました"
      else
        redirect_to team_weekly_scores_path_for_note, alert: @weekly_score_note.errors.full_messages.first
      end
    end

    def update
      return unless completed_week?

      if @weekly_score_note.update(body: weekly_score_note_params[:body])
        redirect_to team_weekly_scores_path_for_note, notice: "週次メモを更新しました"
      else
        redirect_to team_weekly_scores_path_for_note, alert: @weekly_score_note.errors.full_messages.first
      end
    end

    def destroy
      week_start_on = @weekly_score_note.week_start_on
      @weekly_score_note.destroy!

      redirect_to team_weekly_scores_path_for_note(week_start_on), notice: "週次メモを削除しました"
    end

    private

    def authorize_system_admin!
      return if current_user&.system_admin?

      redirect_to admin_team_weekly_scores_path, alert: "週次メモの編集権限が必要です"
    end

    def set_weekly_score_note
      @weekly_score_note = WeeklyScoreNote.find(params[:id])
    end

    def weekly_score_note_params
      params.require(:weekly_score_note).permit(:week_start_on, :body)
    end

    def completed_week?
      return true if completed_week_start_ons.include?(@weekly_score_note.week_start_on)

      redirect_to admin_team_weekly_scores_path, alert: "集計済みの週にのみメモを登録できます"
      false
    end

    def completed_week_start_ons
      @completed_week_start_ons ||= Survey.active
        .where("end_at <= ?", Time.current)
        .where("exists (select 1 from survey_questions where survey_questions.survey_id = surveys.id)")
        .pluck(:start_at)
        .map(&:to_date)
    end

    def note_anchor(week_start_on = @weekly_score_note.week_start_on)
      "weekly-score-note-#{week_start_on}"
    end

    def team_weekly_scores_path_for_note(week_start_on = @weekly_score_note.week_start_on)
      admin_team_weekly_scores_path(note_week: week_start_on, anchor: note_anchor(week_start_on))
    end
  end
end
