# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
roles = Role::ROLE_NAMES.index_with do |role_name|
  Role.find_or_create_by!(name: role_name)
end

Question.ensure_standard_questions!

InitialAdminProvisioner.call if Rails.env.production? && ENV["SEED_ADMIN_EMAIL"].present?

if Rails.env.development?
  admin = User.find_or_initialize_by(email: "admin@example.com")
  admin.update!(name: "管理者サンプル", survey_subject: true)
  admin.roles = [ roles.fetch("system_admin"), roles.fetch("member") ]

  local_admin = User.find_or_initialize_by(email: "kim@localworks.jp")
  local_admin.update!(name: "Kim", survey_subject: true)
  local_admin.roles = [ roles.fetch("system_admin"), roles.fetch("member") ]

  member = User.find_or_initialize_by(email: "member@example.com")
  member.update!(name: "メンバーサンプル", survey_subject: true)
  member.roles = [ roles.fetch("member") ]

  inactive = User.find_or_initialize_by(email: "inactive@example.com")
  inactive.update!(name: "対象外サンプル", survey_subject: false)
  inactive.roles = [ roles.fetch("member") ]

  survey = Survey.find_or_initialize_by(title: "MVPサンプルサーベイ")
  survey.update!(
    status: "active",
    start_at: 1.day.ago,
    end_at: 1.week.from_now
  )

  unless local_admin.next_pending_survey_assignment
    Survey.create!(
      title: "MVP開発確認サーベイ #{Time.current.strftime("%Y%m%d%H%M%S")}",
      status: "active",
      start_at: 1.day.ago,
      end_at: 1.week.from_now
    )
  end
end
