# EffectiveMembershipsUser
#
# Mark your user model with effective_memberships_user to get all the includes

module EffectiveMembershipsUser
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_user
      include ::EffectiveMembershipsUser
    end
  end

  module ClassMethods
    def effective_memberships_user?; true; end
  end

  included do
    effective_memberships_owner

    # App scoped
    has_many :applicants, -> { order(:id) }, inverse_of: :user, as: :user
    has_many :fee_payments, -> { order(:id) }, inverse_of: :user, as: :user

    # Effective Scoped
    has_many :representatives, -> { Effective::Representative.sorted },
      class_name: 'Effective::Representative', inverse_of: :user, dependent: :delete_all

    accepts_nested_attributes_for :representatives, allow_destroy: true

    scope :membership_applying, -> {
      applicants = EffectiveMemberships.Applicant.all
      without_role(:member).where(id: applicants.select(:user_id))
    }
  end

  # Instance Methods
  def memberships
    Array(membership) + membership_organizations.map(&:membership)
  end

  def memberships_owners
    Array(is?(:member) ? self : nil) + membership_organizations
  end

  def membership_present?
    individual_membership_present? || organization_membership_present?
  end

  def individual_membership_present?
    membership.present? && !membership.marked_for_destruction?
  end

  def organization_membership_present?(except: nil)
    organizations.reject(&:archived?).any? { |organization| organization != except && organization.membership_present? }
  end

  def representative(organization:)
    representatives.find { |rep| rep.organization_id == organization.id } if organization
  end

  # Find or build
  def build_representative(organization:)
    representative(organization: organization) || representatives.build(organization: organization)
  end

  def organizations
    representatives.reject(&:marked_for_destruction?).map(&:organization)
  end

  def membership_organizations
    organizations.select { |organization| organization.is?(:member) && !organization.archived? }
  end

end
