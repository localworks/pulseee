class HomeController < ApplicationController
  def index
    @assignment = current_user&.next_pending_survey_assignment
  end
end
