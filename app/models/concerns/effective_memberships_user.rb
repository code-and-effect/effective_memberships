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

  included do
    belongs_to :membership_category, polymorphic: true, optional: true
  end

  module ClassMethods
    def effective_memberships_user?; true; end
  end

end
