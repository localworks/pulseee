google_client_id = ENV["GOOGLE_CLIENT_ID"].presence || Rails.application.credentials.dig(:google_oauth, :client_id)
google_client_secret = ENV["GOOGLE_CLIENT_SECRET"].presence || Rails.application.credentials.dig(:google_oauth, :client_secret)
google_client_id_valid = google_client_id.to_s.match?(/\A[0-9A-Za-z_-]+\.apps\.googleusercontent\.com\z/)
google_client_secret_valid = google_client_secret.present? && !google_client_secret.to_s.match?(/\A(?:dummy|test|your-|sample)/i)
google_auth_configured = google_client_id_valid && google_client_secret_valid
google_auth_mock_enabled = Rails.env.development? && ENV["MOCK_GOOGLE_AUTH"] == "1"

Rails.application.config.x.google_auth_configured = google_auth_configured
Rails.application.config.x.google_auth_mock_enabled = google_auth_mock_enabled

if google_auth_mock_enabled
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
    provider: "google_oauth2",
    uid: "mock-google-oauth2",
    info: {
      email: ENV.fetch("DEV_LOGIN_EMAIL", "kim@localworks.jp"),
      name: "Mock Google User"
    }
  )
end

Rails.application.config.middleware.use OmniAuth::Builder do
  next unless Rails.env.test? || google_auth_configured || google_auth_mock_enabled

  provider :google_oauth2,
    google_client_id || "test-client-id",
    google_client_secret || "test-client-secret",
    scope: "email,profile",
    prompt: "select_account"
end
