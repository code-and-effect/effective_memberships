module Effective
  class Membership < ActiveRecord::Base
    belongs_to :user, polymorphic: true
    belongs_to :category, polymorphic: true

    log_changes(to: :user) if respond_to?(:log_changes)

    effective_resource do
      # Membership Info
      number                   :string   # A unique value
      joined_on                :date     # When they first receive a membership category
      registration_on           :date     # When the membership category last changed. Applied or reclassified.

      # Membership Status
      fees_paid_through_period  :date     # The period they have paid upto.

      in_bad_standing          :boolean   # Calculated value. Is this user in bad standing? (fees due)
      in_bad_standing_reason   :text      # Reason for bad standing
      in_bad_standing_admin    :boolean   # Admin set this

      timestamps
    end

    scope :deep, -> { includes(:category, user: [:fees, :membership]) }
    scope :sorted, -> { order(:id) }

    scope :with_paid_fees_through, -> (period = nil) {
      period ||= EffectiveMemberships.Registrar.current_period
      where(arel_table[:fees_paid_through_period].gteq(period))
    }

    scope :with_unpaid_fees_through, -> (period = nil) {
      period ||= EffectiveMemberships.Registrar.current_period
      where(fees_paid_through_period: nil).or(where(arel_table[:fees_paid_through_period].lt(period)))
    }

    scope :create_renewal_fees, -> (period = nil) {
      deep
        .with_unpaid_fees_through(period)
        .where.not(fees_paid_through_period: nil) # Must have purchased a Prorated or Renewal Fee before
        .where(category_id: EffectiveMemberships.MembershipCategory.create_renewal_fees)
    }

    scope :create_late_fees, -> (period = nil) {
      deep
        .with_unpaid_fees_through(period)
        .where.not(fees_paid_through_period: nil) # Must have purchased a Prorated or Renewal Fee before
        .where(category_id: EffectiveMemberships.MembershipCategory.create_late_fees)
    }

    before_validation { self.registration_on ||= joined_on }

    validates :number, presence: true, uniqueness: true
    validates :joined_on, presence: true
    validates :registration_on, presence: true

    validate(if: -> { category.present? }) do
      self.errors.add(:category_id, 'must be a memberships category') unless category.class.effective_memberships_category?
    end

    validate(if: -> { user.present? }) do
      self.errors.add(:user_id, 'must be a memberships user') unless user.class.effective_memberships_user?
    end

    def self.max_number
      maximum("CAST(number AS integer)") || 0
    end

    def to_s
      'membership'
    end

  end
end
