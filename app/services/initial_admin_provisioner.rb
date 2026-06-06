class InitialAdminProvisioner
  def self.call(email: ENV["SEED_ADMIN_EMAIL"], name: ENV["SEED_ADMIN_NAME"])
    new(email: email, name: name).call
  end

  def initialize(email:, name:)
    @email = email.to_s.strip.downcase
    @name = name.presence || @email.split("@").first
  end

  def call
    return if email.blank?

    roles = Role::ROLE_NAMES.index_with do |role_name|
      Role.find_or_create_by!(name: role_name)
    end

    admin = User.find_or_initialize_by(email: email)
    admin.update!(name: name, survey_subject: true)
    admin.roles = [ roles.fetch("system_admin"), roles.fetch("member") ]
    admin
  end

  private

  attr_reader :email, :name
end
