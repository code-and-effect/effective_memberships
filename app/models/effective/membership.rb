module Effective
  class Membership < ActiveRecord::Base
    belongs_to :owner, polymorphic: true

    has_many :membership_categories, inverse_of: :membership
    accepts_nested_attributes_for :membership_categories

    log_changes(to: :owner) if respond_to?(:log_changes)

    effective_resource do
      # Membership Info
      number                    :string   # A unique value
      number_as_integer         :integer  # A unique integer

      joined_on                 :date     # When they first receive a membership category
      registration_on           :date     # When the membership category last changed. Applied or reclassified.

      # Membership Status
      fees_paid_period          :date     # The most recent period they have paid in. Start date of period.
      fees_paid_through_period  :date     # The most recent period they have paid in. End date of period. Kind of an expires.

      bad_standing              :boolean   # Calculated value. Is this owner in bad standing? (fees due)
      bad_standing_admin        :boolean   # Admin set this
      bad_standing_reason       :text      # Reason for bad standing

      timestamps
    end

    scope :deep, -> { includes(owner: [:fees, :membership]) }
    scope :sorted, -> { order(:id) }

    scope :with_paid_fees_through, -> (period = nil) {
      where(arel_table[:fees_paid_period].gteq(period || EffectiveMemberships.Registrar.current_period))
    }

    scope :with_unpaid_fees_through, -> (period = nil) {
      where(arel_table[:fees_paid_period].lt(period || EffectiveMemberships.Registrar.current_period))
      .or(where(fees_paid_period: nil))
    }

    scope :create_renewal_fees, -> (period = nil) {
      deep.with_unpaid_fees_through(period)
        .where.not(fees_paid_period: nil) # Must have purchased a Prorated or Renewal Fee before
        #.where(category_id: EffectiveMemberships.Category.create_renewal_fees)
    }

    scope :create_late_fees, -> (period = nil) {
      deep.with_unpaid_fees_through(period)
        .where.not(fees_paid_period: nil) # Must have purchased a Prorated or Renewal Fee before
        #.where(category_id: EffectiveMemberships.Category.create_late_fees)
    }

    scope :create_bad_standing, -> (period = nil) {
      deep.with_unpaid_fees_through(period)
        .where.not(fees_paid_period: nil) # Must have purchased a Prorated or Renewal Fee before
        #.where(category_id: EffectiveMemberships.Category.create_bad_standing)
    }

    before_validation do
      self.registration_on ||= joined_on
      self.number_as_integer ||= (Integer(number) rescue nil)
    end

    validates :number, presence: true, uniqueness: true
    validates :joined_on, presence: true
    validates :registration_on, presence: true

    validate(if: -> { owner.present? }) do
      self.errors.add(:owner_id, 'must be a memberships owner') unless owner.class.effective_memberships_owner?
    end

    def self.max_number
      maximum('number_as_integer') || 0
    end

    def to_s
      'membership'
    end

    # We can't use the polymorphic has_many. So this is a helper.
    def categories
      membership_categories.reject(&:marked_for_destruction?).map(&:category)
    end

    def category_ids
      membership_categories.reject(&:marked_for_destruction?).map(&:category_id)
    end

    # We might want to use singular memberships.
    def category
      raise('expected singular usage but there are more than one membership') if categories.length > 1
      categories.first
    end

    def category_id
      raise('expected singular usage but there are more than one membership') if categories.length > 1
      categories.first.id
    end

    def membership_category(category:)
      raise('expected a category') unless category.class.respond_to?(:effective_memberships_category?)
      membership_categories.find { |mc| mc.category_id == category.id && mc.category_type == category.class.name }
    end

    # find or build
    def build_membership_category(category:)
      membership_category(category: category) || membership_categories.build(category: category)
    end

    def good_standing?
      !bad_standing?
    end

  end
end
