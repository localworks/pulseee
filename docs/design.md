# 設計メモ

## 最初のリリースの対象

最初のリリースでは、以下のユーザーストーリーのみを実装対象とする。

- ユーザーは Google 認証でログインできる
- 事前登録ユーザーだけがログインできる
- サーベイ対象者は、有効で未回答のサーベイを見ることができる
- サーベイ対象者は、有効で未回答のサーベイに回答できる
- 期限切れのサーベイは表示できず、回答できない
- 回答済みのサーベイは表示できず、回答修正できない
- 回答可能なサーベイがない場合は「回答が必要なサーベイはありません」と表示する

最初のリリースでは、カテゴリ別集計、全社平均表示、回答率表示画面は作らない。

回答率はSQLで集計できるようにし、回答数だけでなく、回答すべきだった人の数を後から確認できるようにする。

## ユーザー登録

ユーザーは Google 認証に成功しただけでは自動作成しない。

最初のリリースでは、ユーザーは RailsAdmin で登録する。開発環境では `db/seeds.rb` でサンプルデータを作成する。

ユーザーのロールと、サーベイ対象者かどうかは別の属性として管理する。

サーベイ対象者かどうかは `users.survey_subject` の boolean で管理する。

1人のユーザーは複数のロールを持てる。

最初のリリースで扱うロールは以下とする。

- `member`
- `hr`
- `executive`
- `system_admin`
- `manager`

ロールは固定マスタとして `db/seeds.rb` で作成する。

ユーザーへのロール付与は RailsAdmin で行えるが、ロール自体の作成・編集・削除は行わない。

## 認証

Google Auth の実装には `omniauth-google-oauth2` を使う。

認証コールバックで取得したメールアドレスが事前登録ユーザーと一致する場合だけログイン成功とする。

未登録のメールアドレスで Google 認証に成功しても、ユーザーは自動作成せずログイン不可とする。

最初のリリースでは Google アカウントのドメイン制限は設けず、事前登録ユーザーのメールアドレスとの照合だけでログイン可否を判定する。

ログアウト機能は最初のリリースに含める。

ログアウト時はアプリケーションのセッションを破棄する。Google アカウント自体からのログアウトは行わない。

最初のリリースでは、セッションの有効期限は Rails の標準設定に任せ、独自の期限設定は行わない。

## 有効なサーベイ

有効なサーベイは、以下をすべて満たすサーベイとする。

- `status` が `active`
- `start_at` が現在時刻以前
- `end_at` が現在時刻より後

期限切れ判定に使う期間カラムは `start_at` / `end_at` とする。

有効期間の境界は `start_at <= 現在時刻 < end_at` とする。

最初のリリースで扱う `surveys.status` は `draft` / `active` のみとする。

有効で未回答のサーベイが複数ある場合は、`end_at` が最も近い1件を回答対象として表示する。

## 回答対象と回答済み判定

回答すべきだったユーザーは、`survey_assignments` に `(survey_id, user_id)` の組み合わせを作成して固定する。

`survey_assignments` は回答依頼と回答状態を表す。

`survey_assignments.state` が `submitted` の場合に回答済みと判定する。

`survey_assignments` は、サーベイを `draft` から `active` に変更したタイミングで、その時点の `survey_subject = true` のユーザーに対して `pending` として作成する。

`active` 化後に `survey_subject` が `true` になったユーザーは、その既存サーベイの回答対象には追加しない。次回以降のサーベイから対象にする。

`active` 化後に `survey_subject` が `false` になったユーザーも、その既存サーベイの回答対象からは外さない。

サーベイを `active` から `draft` に戻しても、既存の `survey_assignments` は削除しない。

`status = draft` の間は、有効期間内であっても回答画面には表示せず、回答もできない。

`draft` に戻した後に再び `active` にしても、新しく `survey_subject = true` になったユーザーは既存サーベイの回答対象に追加しない。

`survey_assignments` が存在しないサーベイを初めて `active` にした場合だけ、その時点の `survey_subject = true` のユーザーに対して `survey_assignments` を作成する。

定量回答の匿名性を守るため、`score_answers` には `user_id` も `survey_assignment_id` も持たせない。

回答送信時は、`survey_assignments.state` の更新と `score_answers` の作成を同一トランザクションで保存する。

## 回答内容

最初のリリースでは、サーベイは定量設問のみを回答対象とする。

自由記述1問は最初のリリースでは対象外とする。

定量回答は5段階評価とする。

5段階評価の画面表示では、両端のみラベルを表示する。

- `1`: まったくそう思わない
- `5`: とてもそう思う

定量設問は `questions` を元に、各 `survey` に `survey_questions` を作成する。

各 `survey` の `survey_questions` は、その実施回における設問文と並び順を保持する。

`survey` 作成時に、その時点の `questions` を `survey_questions` に自動コピーする。

標準設問が0件の場合、サーベイ作成は失敗させる。

コピー時は `questions.id` の昇順で `survey_questions.order_index` を設定する。

サーベイ作成後に `questions` を変更しても、既存の `survey_questions` には反映しない。

標準設問の変更は、次に作成するサーベイから反映する。

設問数は7問を標準とするが、7問でなくても回答できる。

設問が0問のサーベイは回答不可とし、「回答が必要なサーベイはありません」と表示する。

回答画面に表示された定量設問は、すべて回答必須とする。

未回答の設問がある場合は `survey_assignments` も `score_answers` も更新・保存せず、入力済みの値を保持して回答画面を再表示し、「すべての設問に回答してください」と表示する。

## 管理画面

最初のリリースでは、専用のサーベイ作成画面、設問管理画面、ユーザー管理画面は作らない。

ユーザー、標準設問、サーベイは RailsAdmin で登録・変更・削除する。

開発環境では `db/seeds.rb` でサンプルデータを作成する。

本番運用では Rails console を原則使わず、ユーザー登録用の Rake タスクも作らない。

最初のリリースでは、RailsAdmin で登録・編集する対象を `users`、`questions`、`surveys` に限定する。

`surveys` を削除できるのは、回答が1件もない `draft` のサーベイだけとする。

`questions` は RailsAdmin で削除できないようにする。

`questions.body` の編集は許可するが、既存の `survey_questions` には反映しない。

`users` は RailsAdmin で削除できないようにする。

`users.email` は Google Auth の照合キーとして扱い、RailsAdmin で編集できないようにする。

`users.name`、ロール割当、`survey_subject` は RailsAdmin で編集できるようにする。

ユーザー情報を変更しても、既存サーベイの `survey_assignments` は変更しない。

退職者など次回以降の回答対象から外したいユーザーは、削除せず `survey_subject = false` にする。

`survey_questions` は RailsAdmin で表示のみ許可し、作成・編集・削除はできないようにする。

`survey_assignments` は RailsAdmin で表示のみ許可し、作成・編集・削除はできないようにする。

`score_answers` は RailsAdmin で表示のみ許可し、作成・編集・削除はできないようにする。

RailsAdmin へアクセスできるのは `system_admin` ロールのユーザーだけとする。

未ログインユーザーが RailsAdmin にアクセスした場合は Google Auth のログインへ誘導する。ログイン済みでも `system_admin` ロールを持たない場合は共通ホームへ戻す。

## テスト方針

最初の実装では、モデルテストと統合テストを中心に書く。

- モデルテストでは、有効サーベイ判定、回答済み判定、スコア範囲、ユニーク制約を確認する
- 統合テストでは、ログイン済みユーザーがホームを見る、未回答サーベイに回答する、回答済み・期限切れ・対象外では表示されないことを確認する

Google Auth は OmniAuth のテストモードでスタブし、実際の Google には接続しない。

## データモデル

最初のリリースでは、以下の8テーブルを作成する。

- `users`
- `roles`
- `user_roles`
- `surveys`
- `questions`
- `survey_questions`
- `survey_assignments`
- `score_answers`

自由記述は最初のリリースでは対象外のため、`text_answers` は作成しない。

`survey_questions` は、標準設問への参照に加えて、その実施回における設問文を保持する。

```text
survey_questions
- survey_id
- question_id
- body
- order_index
```

```text
questions
- body
```

```text
roles
- name
```

```text
user_roles
- user_id
- role_id
```

`users` は `role` カラムを持たず、`roles` / `user_roles` で複数ロールを表現する。

`roles.name` は固定値として扱う。

`score_answers` は `submit_token`、`survey_question_id`、`score` を持つ。

`score_answers` には、個人特定につながる `user_id` / `survey_assignment_id` を持たせない。

`submit_token` は回答送信時に作成する一意な文字列とし、1つの `survey_assignments.id` に対応する回答送信内では同じ値を使う。

`submit_token` は `SecureRandom.uuid` のようなランダム値で生成し、`survey_assignments.id` と結びつけられないようにする。`survey_assignments` 側にも保存しない。

`score_answers` には、回答時刻からの推測を避けるため `created_at` / `updated_at` も持たせない。

`score_answers` は回答送信時にのみ作成する追記専用データとし、更新・削除しない。

`score_answers.score` は1〜5の整数とし、アプリケーションとDB制約の両方で範囲を保証する。

`score_answers` の `(submit_token, survey_question_id)` にはユニーク制約を設定する。

回答送信時、`score_answers` の件数が表示された `survey_questions` の件数と一致することは、アプリケーション側で保証する。

`users.email` にはユニーク制約を設定する。

`user_roles` の `(user_id, role_id)` にはユニーク制約を設定する。

`survey_assignments` は `state` を持ち、回答依頼と回答状態を表す。

```text
survey_assignments
- survey_id
- user_id
- state
- submitted_at
```

`survey_assignments.state` は `pending` / `submitted` の2値とする。

`survey_assignments.submitted_at` は回答完了時刻として保存する。

回答率は、`survey_assignments` の件数を分母、`state = submitted` の件数を分子として計算する。

回答済みの `survey_assignments` を未回答へ戻す運用は、最初のリリースでは不可とする。

`survey_assignments` の `(survey_id, user_id)` にはユニーク制約を設定する。

最初のリリースでは質問順のランダム化は行わない。

回答画面では `survey_questions.order_index` の昇順で設問を表示する。

## ログイン後の画面

ログイン後は、すべてのユーザーを共通のホーム画面に遷移させる。

ホーム画面では、有効なサーベイに対する `pending` の `survey_assignments` がある場合だけ、回答画面への導線を表示する。

それ以外の場合は「回答が必要なサーベイはありません」と表示する。

`system_admin` など複数ロールを持つユーザーでも、対象サーベイに対する `pending` の `survey_assignments` があれば回答導線の表示対象になる。

最初のリリースでは、ユーザーごとの配信対象や部署別配信は作らない。

サーベイを `active` にした時点で `survey_subject = true` だったユーザーには、同じ有効サーベイを回答対象として割り当てる。

回答完了後は共通のホーム画面に戻し、完了メッセージとして「回答を送信しました」と表示する。

期限切れ、回答済み、サーベイ対象外のユーザーが回答URLへ直接アクセスした場合は、共通ホームへリダイレクトし「回答が必要なサーベイはありません」と表示する。

回答送信時も同じ回答可否判定を行い、回答できない状態であれば保存せず共通ホームへ戻す。
