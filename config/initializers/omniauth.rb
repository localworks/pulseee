Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", "dummy-client-id"),
    ENV.fetch("GOOGLE_CLIENT_SECRET", "dummy-client-secret"),
    scope: "email,profile",
    prompt: "select_account"
end
