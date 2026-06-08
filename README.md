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

### ローカル開発でGoogle認証をモックする

ローカル開発で実際のGoogle OAuthを使わずに通常のOmniAuthコールバック経路を確認したい場合は、`MOCK_GOOGLE_AUTH=1` を指定してください。

```bash
MOCK_GOOGLE_AUTH=1 bin/rails server
```

モックユーザーのメールアドレスは、既定では seed に含まれる `kim@localworks.jp` です。別の事前登録ユーザーで確認したい場合は `DEV_LOGIN_EMAIL` を指定してください。

```bash
MOCK_GOOGLE_AUTH=1 DEV_LOGIN_EMAIL="member@example.com" bin/rails server
```

## 開発用ログイン

Google認証を設定していない開発環境では、ログイン画面に「開発用ログイン」ボタンが表示されます。

既定では seed に含まれる `admin-dev@example.com` でログインします。

```bash
bin/rails db:seed
bin/rails server
```

サーベイが表示されない場合も、もう一度 `bin/rails db:seed` を実行してください。開発用ログインユーザーに未回答サーベイがない場合、確認用サーベイが作成されます。

別の事前登録ユーザーでログインしたい場合は、`DEV_LOGIN_EMAIL` を指定してください。

```bash
DEV_LOGIN_EMAIL="member@example.com" bin/rails server
```
