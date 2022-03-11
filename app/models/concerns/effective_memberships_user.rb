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

    has_many :representatives, -> { Effective::Representative.sorted },
      class_name: 'Effective::Representative', inverse_of: :user, dependent: :delete_all

    accepts_nested_attributes_for :representatives, allow_destroy: true
  end

  # Instance Methods

  def representative(organization:)
    representatives.find { |rep| rep.organization_id == organization.id }
  end

  # Find or build
  def build_representative(organization:)
    representative(organization: organization) || representatives.build(organization: organization)
  end

  def organizations
    representatives.reject(&:marked_for_destruction?).map(&:organization)
  end

end
