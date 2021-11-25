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

    has_many :fees, -> { Effective::Fee.sorted }, inverse_of: :user, class_name: 'Effective::Fee'

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

  def max_fees_paid_through_period
    fees.select { |fee| fee.membership_period_fee? && fee.purchased? }.max(&:period)
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

    fee = fees.find { |fee| fee.category == 'Prorated' } || fees.build()
    return fee if fee.purchased?

    fee.assign_attributes(
      category: 'Prorated',
      membership_category: membership.category,
      price: price,
      period: period,
      due_at: date
    )

    fee
  end

  def build_renewal_fee(period:, due_at:)
    raise('must have an existing membership') unless membership.present?

    fee = fees.find { |fee| fee.category == 'Renewal' && fee.period == period } || fees.build()
    return fee if fee.purchased?

    fee.assign_attributes(
      category: 'Renewal',
      membership_category: membership.category,
      price: membership.category.renewal_fee.to_i,
      period: period,
      due_at: due_at
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
      due_at: Time.zone.now
    )

    fee
  end

  def assign_current_membership_status
    raise('expected membership to be present') unless membership.present?

    # Assign fees_paid_through_period
    membership.fees_paid_through_period = max_fees_paid_through_period()

    membership.in_bad_standing =
    membership.in_bad_standing ||= membership.in_bad_standing_admin # Admin set it

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
      in_bad_standing: membership.in_bad_standing?
    )
  end

  def membership_history_on(date)
    raise('expected a date') unless date.respond_to?(:strftime)
    membership_histories.find { |history| (history.start_on..history.end_on).cover?(date) } # Ruby 2.6 supports endless ranges
  end

end
