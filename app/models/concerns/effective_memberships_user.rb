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
    has_many :fees

    effective_resource do
      membership_number                   :string   # A unique value
      membership_joined_on                :date     # When they first receive a membership category
      membership_registration_on          :date     # When the membership category last changed. Applied or reclassified.
      membership_fees_paid_through_year   :integer  # The year they have paid upto.

      membership_in_bad_standing             :boolean   # Calculated value. Is this user in bad standing? (fees due)
      membership_in_bad_standing_reason      :text      # Reason for bad standing
      membership_in_bad_standing_admin       :boolean   # Admin set this

      timestamps
    end

  end

end
