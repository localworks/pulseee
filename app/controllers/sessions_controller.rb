class SessionsController < ApplicationController
  def missing_google_configuration
    redirect_to login_path, alert: "Google認証の設定が未完了です"
  end

  def development_login
    return head :not_found unless Rails.env.development?

    user = User.find_by(email: ENV.fetch("DEV_LOGIN_EMAIL", "kim@localworks.jp"))

    if user
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "開発用ログインしました"
    else
      redirect_to login_path, alert: "開発用ユーザーが見つかりません。bin/rails db:seed を実行してください"
    end
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by(email: auth_email(auth))

    if user
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "ログインしました"
    else
      reset_session
      redirect_to login_path, alert: "登録済みのGoogleアカウントでログインしてください"
    end
  end

  def failure
    redirect_to login_path, alert: "Google認証に失敗しました"
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "ログアウトしました"
  end

  private

  def auth_email(auth)
    auth&.dig("info", "email").to_s.strip.downcase
  end
end
