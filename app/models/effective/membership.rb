module Effective
  class Membership < ActiveRecord::Base
    belongs_to :owner, polymorphic: true

    attr_accessor :current_action

    has_many :membership_categories, -> { order(:id) }, inverse_of: :membership, dependent: :delete_all
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

    scope :deep, -> { includes(membership_categories: :category) }
    scope :sorted, -> { order(:id) }

    scope :good_standing, -> { where(bad_standing: [nil, false]) }

    scope :with_paid_fees_through, -> (period = nil) {
      where(arel_table[:fees_paid_period].gteq(period || EffectiveMemberships.Registrar.current_period))
    }

    scope :with_unpaid_fees_through, -> (period = nil) {
      joined = where(arel_table[:joined_on].lt(period || EffectiveMemberships.Registrar.current_period))
      unpaid = where(arel_table[:fees_paid_period].lt(period || EffectiveMemberships.Registrar.current_period)).or(where(fees_paid_period: nil))
      joined.merge(unpaid)
    }

    before_validation do
      self.registration_on ||= joined_on
    end

    before_validation(if: -> { number_changed? }) do
      self.number_as_integer = (Integer(number) rescue nil)
    end

    validates :number, presence: true, uniqueness: true
    validates :joined_on, presence: true
    validates :registration_on, presence: true
    validates :membership_categories, presence: true

    validate(if: -> { owner.present? }) do
      self.errors.add(:owner_id, 'must be a memberships owner') unless owner.class.effective_memberships_owner?
    end

    validate(if: -> { registration_on.present? && joined_on.present? }) do
      self.errors.add(:registration_on, 'must match or be greater than the joined date') if registration_on < joined_on
    end

    def self.max_number
      maximum('number_as_integer') || 0
    end

    def to_s
      return 'membership' if owner.blank?

      summary = [
        owner.to_s,
        'is',
        (categories.to_sentence),
        'member',
        "##{number_was}",
        "who joined #{joined_on&.strftime('%F') || '-'}",
        ("and last registered #{registration_on.strftime('%F')}" if registration_on > joined_on),
        (". Membership is Not In Good Standing because #{bad_standing_reason}" if bad_standing?)
      ].compact.join(' ')

      (summary + '.').html_safe
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

    def fees_paid?
      paid_fees_through?(EffectiveMemberships.Registrar.current_period)
    end

    def paid_fees_through?(period = nil)
      period ||= EffectiveMemberships.Registrar.current_period

      return false if fees_paid_period.blank?
      fees_paid_period >= period
    end

    def unpaid_fees_through?(period = nil)
      period ||= EffectiveMemberships.Registrar.current_period

      return false if joined_on.blank?
      return false unless joined_on < period

      return true if fees_paid_period.blank?
      fees_paid_period < period
    end

    def change_fees_paid_period
      fees_paid_period
    end

    def change_fees_paid_period=(date)
      if date.blank?
        return assign_attributes(fees_paid_period: nil, fees_paid_through_period: nil)
      end

      date = (date.respond_to?(:strftime) ? date : Date.parse(date))

      period = EffectiveMemberships.Registrar.period(date: date)
      period_end_on = EffectiveMemberships.Registrar.period_end_on(date: date)

      assign_attributes(fees_paid_period: period, fees_paid_through_period: period_end_on)
    end

    # Admin updating membership info
    def revise!
      save!

      period = EffectiveMemberships.Registrar.current_period
      return true if paid_fees_through?(period)

      # Otherwise build fees right now
      EffectiveMemberships.Registrar.create_renewal_fees!(self, period: period)
      EffectiveMemberships.Registrar.create_late_fees!(self, period: period)
      EffectiveMemberships.Registrar.update_membership_status!(self, period: period)

      true
    end

  end
end
