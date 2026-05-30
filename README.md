# pulseee

## Google認証の設定

Googleログインを使うには、アプリ起動前に OAuth Client ID / Secret を設定してください。

```bash
export GOOGLE_CLIENT_ID="your-google-oauth-client-id"
export GOOGLE_CLIENT_SECRET="your-google-oauth-client-secret"
bin/rails server
```

Rails credentials を使う場合は以下のキーでも読み込めます。

```yaml
google_oauth:
  client_id: your-google-oauth-client-id
  client_secret: your-google-oauth-client-secret
```

Google Cloud Console 側の承認済みリダイレクトURIには、ローカル開発では以下を登録してください。

```text
http://localhost:3000/auth/google_oauth2/callback
http://127.0.0.1:3000/auth/google_oauth2/callback
```
