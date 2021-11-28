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
    has_many :fee_payments

    has_many :fees, -> { order(:id) }, inverse_of: :user, class_name: 'Effective::Fee', dependent: :nullify
    accepts_nested_attributes_for :fees, reject_if: :all_blank, allow_destroy: true

    has_one :membership, inverse_of: :user, class_name: 'Effective::Membership'
    accepts_nested_attributes_for :membership

    has_many :membership_histories, -> { Effective::MembershipHistory.sorted }, inverse_of: :user, class_name: 'Effective::MembershipHistory'
    accepts_nested_attributes_for :membership_histories

    effective_resource do
      timestamps
    end

    scope :members, -> { joins(:membership) }
  end

  def outstanding_fee_payment_fees
    fees.select { |fee| fee.fee_payment_fee? && !fee.purchased? }
  end

  def bad_standing_fees
    fees.select { |fee| fee.bad_standing? }
  end

  def max_fees_paid_through_period
    fees.select { |fee| fee.membership_period_fee? && fee.purchased? }.map(&:period).max
  end

  # Instance Methods
  def additional_fee_attributes(fee)
    raise('expected an Effective::Fee') unless fee.kind_of?(Effective::Fee)
    {}
  end

  def build_prorated_fee(date: nil)
    raise('must have an existing membership') unless membership.present?

    date ||= Time.zone.now
    price = membership.category.prorated_fee(date: date)
    period = EffectiveMemberships.Registrar.period(date: date)
    category = membership.category

    fee = fees.find { |fee| fee.category == 'Prorated' && fee.period == period && fee.membership_category == category } || fees.build()
    return fee if fee.purchased?

    fee.assign_attributes(
      category: 'Prorated',
      membership_category: category,
      price: price,
      period: period
    )

    fee
  end

  def build_discount_fee(from:, date: nil)
    raise('must have an existing membership') unless membership.present?
    raise('existing membership category may not be same as from') if membership.category == from

    date ||= Time.zone.now
    price = from.discount_fee(date: date)
    period = EffectiveMemberships.Registrar.period(date: date)
    category = membership.category

    fee = fees.find { |fee| fee.category == 'Discount' && fee.period == period && fee.membership_category == category } || fees.build()
    return fee if fee.purchased?

    fee.assign_attributes(
      category: 'Discount',
      membership_category: category,
      price: price,
      period: period
    )

    fee
  end

  def build_renewal_fee(period:, late_on:, bad_standing_on:)
    raise('must have an existing membership') unless membership.present?

    fee = fees.find { |fee| fee.category == 'Renewal' && fee.period == period } || fees.build()
    return fee if fee.purchased?

    fee.assign_attributes(
      category: 'Renewal',
      membership_category: membership.category,
      price: membership.category.renewal_fee.to_i,
      period: period,
      late_on: late_on,
      bad_standing_on: bad_standing_on
    )

    fee
  end

  def build_late_fee(period:)
    raise('must have an existing membership') unless membership.present?

    # Return existing but do not build yet
    fee = fees.find { |fee| fee.category == 'Late' && fee.period == period }
    return fee if fee&.purchased?

    # Only continue if there is a late renewal fee for the same period
    renewal_fee = fees.find { |fee| fee.category == 'Renewal' && fee.period == period }
    return unless fee.present? || renewal_fee&.late?

    # Build the late fee
    fee ||= fees.build()

    fee.assign_attributes(
      category: 'Late',
      membership_category: membership.category,
      price: membership.category.late_fee.to_i,
      period: period,
    )

    fee
  end

  def update_membership_status!
    raise('expected membership to be present') unless membership.present?

    # Assign fees paid through period
    membership.fees_paid_through_period = max_fees_paid_through_period()

    # Assign in bad standing
    if membership.bad_standing_admin?
      # Nothing to do
    elsif bad_standing_fees.present?
      membership.bad_standing = true
      membership.bad_standing_reason = 'Unpaid Fees'
    else
      membership.bad_standing = false
      membership.bad_standing_reason = nil
    end

    if membership.bad_standing_changed? || membership_histories.blank?
      build_membership_history()
      save!
    end

    true
  end

  def build_membership_history(start_on: nil)
    raise('expected membership to be present') unless membership.present?

    # The date of change
    start_on ||= Time.zone.now

    # End the other membership histories
    membership_histories.each { |history| history.end_on ||= start_on }

    # Snapshot of the current membership at this time
    membership_histories.build(
      start_on: start_on,
      end_on: nil,
      membership_category: membership.category,
      number: membership.number,
      bad_standing: membership.bad_standing?
    )
  end

  def membership_history_on(date)
    raise('expected a date') unless date.respond_to?(:strftime)
    membership_histories.find { |history| (history.start_on..history.end_on).cover?(date) } # Ruby 2.6 supports endless ranges
  end

end
