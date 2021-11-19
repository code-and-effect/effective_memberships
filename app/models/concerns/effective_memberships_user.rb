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
    has_many :applicants
    has_many :fees

    has_one :membership, class_name: 'Effective::Membership'
    accepts_nested_attributes_for :membership

    has_many :membership_histories, -> { Effective::MembershipHistory.sorted }, class_name: 'Effective::MembershipHistory'
    accepts_nested_attributes_for :membership_histories

    effective_resource do
      timestamps
    end

  end

end
