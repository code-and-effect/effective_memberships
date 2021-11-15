class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  acts_as_addressable :billing
  effective_memberships_user

  has_many :applicants, class_name: 'Effective::Applicant'
  has_many :fees, class_name: 'Effective::Fee'
end
