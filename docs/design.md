# PULSEEE 設計ドキュメント

---

## URL設計

### 基本方針

- RESTfulに沿った設計
- ロールによるアクセス制御はURLではなくサーバー側で行う
- 従業員は常に「今週のサーベイ」に自動解決される `/survey` にアクセスする
- ダッシュボードは `/dashboard` に統一し、権限ごとの差分はサーバー側で出し分ける
- HR専用の管理機能は名前空間（`/hr/`）で分離する
- ネストは2階層まで

---

### URL一覧

#### 認証

| 画面             | URL                         | メソッド | 備考                 |
| ---------------- | --------------------------- | -------- | -------------------- |
| S1 ログイン      | `/login`                    | GET      | ログイン導線         |
| S1 Googleログイン | `/login/google`             | POST     | Googleアカウントでログイン |
| S1E ログイン失敗 | `/login`                    | GET      | ドメイン不一致などをバリデーションメッセージで表示 |
| ログアウト       | `/logout`                   | DELETE   | セッション破棄       |

#### 従業員向け

| 画面              | URL                   | メソッド | 備考                          |
| ----------------- | --------------------- | -------- | ----------------------------- |
| S2 回答フォーム   | `/survey`             | GET      | 今週のサーベイに自動解決。未実施・期限切れも同画面で表示 |
| S2 回答送信       | `/survey`             | POST     | 送信完了後 S3A へリダイレクト |
| S3A 回答済み      | `/survey/thanks`      | GET      | 送信後リダイレクト先          |
| S10 目安箱        | `/survey/box`         | GET      | アンケート回答フロー内        |
| S10 目安箱投稿    | `/survey/box`         | POST     |                               |

#### ダッシュボード

| 画面              | URL          | メソッド | 備考                                      |
| ----------------- | ------------ | -------- | ----------------------------------------- |
| S4 ダッシュボード | `/dashboard` | GET      | ロール: manager / hr。メニューは権限で出し分け |

#### 人事担当者向け

| 画面                    | URL                                | メソッド | 備考                   |
| ----------------------- | ---------------------------------- | -------- | ---------------------- |
| S5 従業員一覧           | `/hr/users`                    | GET      |                        |
| S5 従業員追加フォーム   | `/hr/users/new`                | GET      |                        |
| S5 従業員作成           | `/hr/users`                    | POST     |                        |
| S5 従業員編集フォーム   | `/hr/users/:id/edit`           | GET      |                        |
| S5 従業員更新           | `/hr/users/:id`                | PATCH    | ロール・有効無効の変更 |
| S6 サーベイ一覧         | `/hr/surveys`                      | GET      |                        |
| S6 サーベイ作成フォーム | `/hr/surveys/new`                  | GET      |                        |
| S6 サーベイ保存         | `/hr/surveys`                      | POST     |                        |
| S6 サーベイ詳細         | `/hr/surveys/:id`                  | GET      | 未回答者一覧・リマインド送信操作を表示 |
| S6 リマインド送信       | `/hr/surveys/:id/remind`           | POST     | S6詳細内の操作、個別 |
| S10 目安箱管理          | `/hr/box`                          | GET      | 全投稿閲覧・管理       |

---

### ルーティング

```ruby
# config/routes.rb
Rails.application.routes.draw do

  # 認証
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  devise_scope :user do
    get    '/login',        to: 'sessions#new'
    post   '/login/google', to: 'sessions#google'
    delete '/logout',       to: 'devise/sessions#destroy'
  end

  # ログイン後のルート振り分け
  root to: 'dashboards#redirect'
  get '/dashboard', to: 'dashboards#show', as: :dashboard

  # 従業員向け
  resource :survey, only: [:show, :create], controller: 'answers' do
    get :thanks

    resource :box, only: [:show, :create], controller: 'box'
  end

  # 人事担当者
  namespace :hr do
    resources :users, except: [:show, :destroy]

    resources :surveys, except: [:destroy] do
      post :remind, on: :member
    end

    resource :box, only: [:show], controller: 'box'
  end

end
```

---

### ログイン後のリダイレクト

ロールに応じて遷移先を振り分ける。

```ruby
# app/controllers/dashboards_controller.rb
class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def redirect
    role = current_user.role

    case role
    when 'hr', 'manager' then redirect_to dashboard_path
    when 'employee' then redirect_to survey_path
    else
      Rails.logger.warn("Unexpected user role: #{role.inspect}")
      redirect_to login_path
    end
  end
end
```

---

### アクセス制御の方針

ダッシュボードは共通URLにし、表示内容やメニューを権限で出し分ける。HR専用の管理機能はサーバー側でも必ずロールチェックを行う。

```ruby
# app/controllers/dashboards_controller.rb
class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_manager_or_hr!, only: [:show]

  private

  def require_manager_or_hr!
    redirect_to survey_path unless current_user.manager? || current_user.hr?
  end
end

# app/controllers/hr/base_controller.rb
class Hr::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_hr!

  private

  def require_hr!
    redirect_to dashboard_path unless current_user.hr?
  end
end
```

## 画面遷移図
```mermaid
flowchart TD
    classDef common   fill:#F1EFE8,stroke:#5F5E5A,color:#444441
    classDef employee fill:#E1F5EE,stroke:#0F6E56,color:#085041
    classDef manager  fill:#EEEDFE,stroke:#534AB7,color:#26215C
    classDef hr       fill:#FAECE7,stroke:#993C1D,color:#712B13
    classDef error    fill:#F5F5F3,stroke:#B4B2A9,color:#888780

    S1["S1 ログイン\n/login\nGoogleログイン: /login/google"]:::common
    S1E["S1E ログイン失敗\n/login\n会社ドメイン以外はバリデーション表示"]:::error
    SX["セッション切れ\n全画面から発生"]:::error

    S1 -- ドメイン不一致 --> S1E
    S1E -. /login上で再試行 .-> S1
    SX -. /loginへリダイレクト .-> S1

    S1 -- employee --> S2
    S1 -- manager / hr --> S4

    S2["S2 回答フォーム\n/survey\n質問7問・5段階＋自由記述"]:::employee
    S2E["S2E 未実施状態\n/survey内で表示"]:::error
    S3A["S3A 回答済み画面\n/survey/thanks"]:::employee
    S3B["S3B 期限切れ状態\n/survey内で表示"]:::error
    S10_EMP["S10 目安箱\n/survey/box\n投稿閲覧・いいね（従業員）"]:::employee

    S2 -. サーベイ未作成時は同画面で表示 .-> S2E
    S2E -. 作成後 .-> S2
    S2 -- 送信 --> S3A
    S2 -. 期限切れ時は同画面で表示 .-> S3B
    S3A -- 目安箱を見る --> S10_EMP

    S4["S4 ダッシュボード\n/dashboard\nサーベイ分析結果\nメニューは権限で出し分け"]:::common
    S5["S5 従業員管理\n/hr/users\n人事担当者のみ"]:::hr
    S6["S6 サーベイ管理\n/hr/surveys\n詳細に未回答者一覧・リマインド操作を含む\n人事担当者のみ"]:::hr
    S10_HR["S10 目安箱管理\n/hr/box\n全投稿閲覧・管理"]:::hr

    S4 -- HRメニュー --> S5
    S4 -- HRメニュー --> S6
    S4 -- HRメニュー --> S10_HR
    S6 -. リマインド送信\nPOST /hr/surveys/:id/remind .-> S6
    S5 -. サイドバー .-> S4
    S6 -. サイドバー .-> S4
    S10_HR -. サイドバー .-> S4
```
