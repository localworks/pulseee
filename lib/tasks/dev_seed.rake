namespace :dev do
  desc "Seed development data for checking team score and response rate layouts"
  task seed_team_score_response_rates: :environment do
    abort "development環境でのみ実行できます" unless Rails.env.development?

    roles = Role::ROLE_NAMES.index_with { |role_name| Role.find_or_create_by!(name: role_name) }
    Question.ensure_standard_questions!

    admin = User.find_or_initialize_by(email: "layout-admin@example.com")
    admin.update!(name: "レイアウト確認 管理者", survey_subject: false)
    admin.roles = [ roles.fetch("system_admin"), roles.fetch("member") ]

    dev_login_admin = User.find_or_initialize_by(email: ENV.fetch("DEV_LOGIN_EMAIL", "kim@localworks.jp"))
    dev_login_admin.update!(name: "開発用ログイン 管理者", survey_subject: false)
    dev_login_admin.roles = [ roles.fetch("system_admin"), roles.fetch("member") ]

    manager = User.find_or_initialize_by(email: "layout-manager@example.com")
    manager.update!(name: "レイアウト確認 マネージャー", survey_subject: false)
    manager.roles = [ roles.fetch("manager"), roles.fetch("member") ]

    groups = %w[開発 営業 CS].index_with { |name| Group.find_or_create_by!(name: name) }
    subjects = [
      [ "開発 田中", "layout-dev-1@example.com", groups.fetch("開発") ],
      [ "開発 鈴木", "layout-dev-2@example.com", groups.fetch("開発") ],
      [ "開発 佐藤", "layout-dev-3@example.com", groups.fetch("開発") ],
      [ "営業 山田", "layout-sales-1@example.com", groups.fetch("営業") ],
      [ "営業 高橋", "layout-sales-2@example.com", groups.fetch("営業") ],
      [ "CS 伊藤", "layout-cs-1@example.com", groups.fetch("CS") ],
      [ "CS 渡辺", "layout-cs-2@example.com", groups.fetch("CS") ],
      [ "未設定 小林", "layout-unset-1@example.com", nil ]
    ].map do |name, email, group|
      User.find_or_initialize_by(email: email).tap do |user|
        user.update!(name: name, survey_subject: true, group: group)
        user.roles = [ roles.fetch("member") ]
      end
    end

    base_week = Date.current.beginning_of_week(:monday) - 7.weeks
    submitted_patterns = [
      [ 0, 1, 3, 5, 7 ],
      [ 0, 1, 2, 3, 5, 6 ],
      [ 0, 3, 4, 5 ],
      [ 0, 1, 2, 3, 4, 5, 6, 7 ],
      [ 1, 3, 5 ],
      [ 0, 2, 4, 6 ],
      [ 0, 1, 3, 4, 5 ],
      [ 0, 3, 5, 7 ]
    ]

    8.times do |week_index|
      week_start_on = base_week + week_index.weeks
      survey = Survey.find_or_initialize_by(title: "レイアウト確認サーベイ #{week_start_on.iso8601}")
      survey.update!(
        status: :active,
        start_at: week_start_on.in_time_zone,
        end_at: (week_start_on + 3.days).in_time_zone
      )

      subjects.each do |user|
        survey.survey_assignments.find_or_create_by!(user: user) do |assignment|
          assignment.state = :pending
        end
      end

      submitted_patterns.fetch(week_index).each do |subject_index|
        assignment = survey.survey_assignments.find_by!(user: subjects.fetch(subject_index))
        next if assignment.submitted?

        submit_token = SecureRandom.uuid
        survey.survey_questions.ordered.each_with_index do |survey_question, question_index|
          ScoreAnswer.create!(
            submit_token: submit_token,
            survey_question: survey_question,
            score: ((week_index + subject_index + question_index) % 5) + 1
          )
        end
        AnswerGroupSnapshot.create!(submit_token: submit_token, group_name: assignment.user.group&.name)
        assignment.update!(state: :submitted, submitted_at: survey.end_at - 1.hour)
      end
    end

    puts "チームスコア・回答率のレイアウト確認用データを作成しました"
    puts "dev login admin: #{dev_login_admin.email}"
    puts "admin: layout-admin@example.com"
    puts "manager: layout-manager@example.com"
  end
end
