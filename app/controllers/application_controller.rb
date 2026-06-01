class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  private

  def authenticate_user!
    return if current_user

    redirect_to root_path, alert: "ログインしてください"
  end
end
