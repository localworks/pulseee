module Surveys
  class CreateCurrentWeekSurvey
    class NotCreationDayError < StandardError; end

    def self.call(now: Time.current, allow_any_day: Rails.env.development?)
      new(now: now, allow_any_day: allow_any_day).call
    end

    def self.current_period(now: Time.current, allow_any_day: Rails.env.development?)
      date = now.in_time_zone.to_date
      return nil unless date.thursday? || allow_any_day

      start_at = date.in_time_zone

      [ start_at, start_at + 3.days ]
    end

    def self.current_survey(now: Time.current, allow_any_day: Rails.env.development?)
      period = current_period(now: now, allow_any_day: allow_any_day)
      return nil unless period

      start_at, end_at = period

      Survey.find_by(start_at: start_at, end_at: end_at) ||
        (Survey.active.where("start_at <= ? and end_at > ?", now, now).order(:start_at).first if allow_any_day)
    end

    def initialize(now:, allow_any_day:)
      @now = now
      @allow_any_day = allow_any_day
    end

    def call
      period = self.class.current_period(now: now, allow_any_day: allow_any_day)
      raise NotCreationDayError, "サーベイを作成できるのは木曜日のみです" unless period

      start_at, end_at = period
      survey = self.class.current_survey(now: now, allow_any_day: allow_any_day) ||
        Survey.new(start_at: start_at, end_at: end_at)

      survey.title = default_title(start_at) if survey.new_record?
      survey.status = :active unless survey.active?
      survey.save! if survey.new_record? || survey.changed?

      survey
    end

    private

    attr_reader :now, :allow_any_day

    def default_title(start_at)
      start_at.to_date.iso8601
    end
  end
end
