google_client_id = ENV["GOOGLE_CLIENT_ID"].presence || Rails.application.credentials.dig(:google_oauth, :client_id)
google_client_secret = ENV["GOOGLE_CLIENT_SECRET"].presence || Rails.application.credentials.dig(:google_oauth, :client_secret)
google_auth_configured = google_client_id.present? && google_client_secret.present?

Rails.application.config.x.google_auth_configured = google_auth_configured

Rails.application.config.middleware.use OmniAuth::Builder do
  next unless Rails.env.test? || google_auth_configured

  provider :google_oauth2,
    google_client_id || "test-client-id",
    google_client_secret || "test-client-secret",
    scope: "email,profile",
    prompt: "select_account"
end
