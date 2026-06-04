# frozen_string_literal: true

require_dependency Rails.root.join("app/services/survey_result_csv_exporter").to_s

module RailsAdmin
  module Config
    module Actions
      class DownloadSurveyResults < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member do
          true
        end

        register_instance_option :only do
          "Survey"
        end

        register_instance_option :visible? do
          authorized?
        end

        register_instance_option :controller do
          proc do
            require_dependency Rails.root.join("app/services/survey_result_csv_exporter").to_s

            csv = ::SurveyResultCsvExporter.new(@object).generate

            send_data csv,
                      filename: "survey-#{@object.id}-results.csv",
                      type: "text/csv; charset=utf-8",
                      disposition: "attachment"
          end
        end

        register_instance_option :link_icon do
          "fas fa-file-csv"
        end

        register_instance_option :turbo? do
          false
        end
      end
    end
  end
end
