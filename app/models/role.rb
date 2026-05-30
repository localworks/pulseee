class Role < ApplicationRecord
  ROLE_NAMES = %w[member hr executive system_admin manager].freeze

  has_many :user_roles, dependent: :restrict_with_error
  has_many :users, through: :user_roles

  validates :name, presence: true, inclusion: { in: ROLE_NAMES }, uniqueness: true
end
