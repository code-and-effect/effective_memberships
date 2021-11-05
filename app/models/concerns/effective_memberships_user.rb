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
    belongs_to :membership_category, optional: true

    has_many :applicants

    effective_resource do
      membership_joined_on    :date

      timestamps
    end

  end

end
