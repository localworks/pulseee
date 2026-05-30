require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "email is normalized and unique" do
    User.create!(name: "利用者", email: "USER@example.com", survey_subject: true)
    duplicate = User.new(name: "重複", email: " user@example.com ", survey_subject: true)

    assert_not duplicate.valid?
    assert_equal "user@example.com", duplicate.email
  end

  test "system admin role check" do
    role = Role.create!(name: "system_admin")
    user = User.create!(name: "管理者", email: "admin@example.com")

    assert_not user.system_admin?

    user.roles << role

    assert user.system_admin?
  end
end
