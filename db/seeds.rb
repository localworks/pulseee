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

questions = [
  "仕事に必要な情報が十分に共有されている",
  "自分の役割や期待されている成果が明確である",
  "チーム内で安心して意見を言える",
  "現在の業務量は適切である",
  "上司やチームから必要な支援を受けられている",
  "会社の方針や優先順位に納得感がある",
  "今の組織で働き続けたいと思う"
]

questions.each do |body|
  Question.find_or_create_by!(body: body)
end

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
