class SessionsController < ApplicationController
  def missing_google_configuration
    redirect_to root_path, alert: "Google認証の設定が未完了です"
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by(email: auth_email(auth))

    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "ログインしました"
    else
      reset_session
      redirect_to root_path, alert: "登録済みのGoogleアカウントでログインしてください"
    end
  end

  def failure
    redirect_to root_path, alert: "Google認証に失敗しました"
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  private

  def auth_email(auth)
    auth&.dig("info", "email").to_s.strip.downcase
  end
end
