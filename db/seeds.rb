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
  dev_group     = Group.find_or_create_by!(name: "開発")
  mensapo_group = Group.find_or_create_by!(name: "メンサポ")
  sales_group   = Group.find_or_create_by!(name: "営業")

  users_data = [
    { email: "admin-dev@example.com",    name: "Dev Admin",    survey_subject: true,  group: dev_group,     role_names: %w[system_admin member] },
    { email: "dev-1@example.com",        name: "Dev User 1",   survey_subject: true,  group: dev_group,     role_names: %w[member] },
    { email: "dev-2@example.com",        name: "Dev User 2",   survey_subject: true,  group: dev_group,     role_names: %w[member] },
    { email: "dev-3@example.com",        name: "Dev User 3",   survey_subject: true,  group: dev_group,     role_names: %w[member] },
    { email: "dev-4@example.com",        name: "Dev User 4",   survey_subject: true,  group: dev_group,     role_names: %w[member] },
    { email: "dev-5@example.com",        name: "Dev User 5",   survey_subject: true,  group: dev_group,     role_names: %w[member] },
    { email: "admin-mensapo@example.com", name: "Mensapo Admin", survey_subject: true, group: mensapo_group, role_names: %w[system_admin member] },
    { email: "mensapo-1@example.com",    name: "Mensapo User 1", survey_subject: true, group: mensapo_group, role_names: %w[member] },
    { email: "mensapo-2@example.com",    name: "Mensapo User 2", survey_subject: true, group: mensapo_group, role_names: %w[member] },
    { email: "mensapo-3@example.com",    name: "Mensapo User 3", survey_subject: true, group: mensapo_group, role_names: %w[member] },
    { email: "mensapo-4@example.com",    name: "Mensapo User 4", survey_subject: true, group: mensapo_group, role_names: %w[member] },
    { email: "sales-1@example.com",      name: "Sales User 1", survey_subject: true,  group: sales_group,   role_names: %w[member] },
    { email: "sales-2@example.com",      name: "Sales User 2", survey_subject: true,  group: sales_group,   role_names: %w[member] },
    { email: "sales-3@example.com",      name: "Sales User 3", survey_subject: true,  group: sales_group,   role_names: %w[member] },
    { email: "inactive@example.com",     name: "Inactive User", survey_subject: false, group: nil,          role_names: %w[member] }
  ]

  users_data.each do |data|
    user = User.find_or_initialize_by(email: data[:email])
    user.update!(name: data[:name], survey_subject: data[:survey_subject], group: data[:group])
    user.roles = data[:role_names].map { |r| roles.fetch(r) }
  end

  local_admin = User.find_by!(email: "admin-dev@example.com")

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
