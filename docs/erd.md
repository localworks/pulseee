# 最初のリリースのER図

定量回答の匿名性を守るため、`SCORE_ANSWERS` は `USERS` および
`SURVEY_ASSIGNMENTS` と関連を持たず、回答時刻も保存しない。

```mermaid
erDiagram

    USERS {
        int id PK
        string name
        string email
        boolean survey_subject
    }

    ROLES {
        int id PK
        string name
    }

    USER_ROLES {
        int id PK
        int user_id FK
        int role_id FK
    }

    QUESTIONS {
        int id PK
        string body
    }

    SURVEYS {
        int id PK
        string title
        string status
        datetime start_at
        datetime end_at
    }

    SURVEY_QUESTIONS {
        int id PK
        int survey_id FK
        int question_id FK
        string body
        int order_index
    }

    SURVEY_ASSIGNMENTS {
        int id PK
        int survey_id FK
        int user_id FK
        string state
        datetime submitted_at
        %% UNIQUE (survey_id, user_id)
    }

    SCORE_ANSWERS {
        int id PK
        string submit_token
        int survey_question_id FK
        int score
        %% UNIQUE (submit_token, survey_question_id)
        %% created_at / updated_at を持たない
    }

    USERS ||--o{ USER_ROLES : has
    ROLES ||--o{ USER_ROLES : assigned
    USERS ||--o{ SURVEY_ASSIGNMENTS : assigned
    SURVEYS ||--o{ SURVEY_ASSIGNMENTS : has
    SURVEYS ||--o{ SURVEY_QUESTIONS : has
    QUESTIONS ||--o{ SURVEY_QUESTIONS : copied_to
    SURVEY_QUESTIONS ||--o{ SCORE_ANSWERS : answered_by
```

## 制約

- `USERS.email` はユニークとする。
- `USER_ROLES` の `(user_id, role_id)` はユニークとする。
- `SURVEY_ASSIGNMENTS` の `(survey_id, user_id)` はユニークとする。
- `SURVEYS.status` は `draft` / `active` のいずれかとする。
- `SURVEY_ASSIGNMENTS.state` は `pending` / `submitted` のいずれかとする。
- `SCORE_ANSWERS.score` は `1` から `10` の整数とする。
- `SCORE_ANSWERS.submit_token` は `SURVEY_ASSIGNMENTS` に保存せず、個人の回答と結び付けない。

自由記述に用いるテーブルは、最初のリリースでは作成しない。
