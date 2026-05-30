require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "registered user can login with google auth mock" do
    User.create!(name: "登録済み", email: "registered@example.com")
    mock_google_auth("registered@example.com")

    post "/auth/google_oauth2"
    follow_all_redirects

    assert_response :success
    assert_select ".flash.notice", text: "ログインしました"
  end

  test "unregistered google auth user cannot login" do
    mock_google_auth("unknown@example.com")

    post "/auth/google_oauth2"
    follow_all_redirects

    assert_response :success
    assert_select ".flash.alert", text: "登録済みのGoogleアカウントでログインしてください"
  end

  test "rails admin is restricted to system admins" do
    system_admin_role = Role.create!(name: "system_admin")
    admin = User.create!(name: "管理者", email: "admin@example.com")
    admin.roles << system_admin_role
    member = User.create!(name: "一般", email: "member@example.com")

    get rails_admin_path
    follow_redirect!
    assert_select ".flash.alert", text: "ログインしてください"

    login_as(member)
    get rails_admin_path
    follow_redirect!
    assert_select ".flash.alert", text: "管理者権限が必要です"

    login_as(admin)
    get rails_admin_path
    assert_response :success
  end

  private

  def mock_google_auth(email)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-#{email}",
      info: { email: email, name: "Google User" }
    )
  end

  def login_as(user)
    mock_google_auth(user.email)
    post "/auth/google_oauth2"
    follow_all_redirects
  end

  def follow_all_redirects
    follow_redirect! while response.redirect?
  end
end
