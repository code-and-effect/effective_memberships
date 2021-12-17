# frozen_string_literal: true

# EffectiveMembershipsOwner
#
# Mark your owner model with effective_memberships_owner to get all the includes

module EffectiveMembershipsOwner
  extend ActiveSupport::Concern

  mattr_accessor :descendants

  module Base
    def effective_memberships_owner
      include ::EffectiveMembershipsOwner
      (EffectiveMembershipsOwner.descendants ||= []) << self
    end
  end

  module ClassMethods
    def effective_memberships_owner?; true; end
  end

  included do
    # App scoped
    has_many :applicants, as: :owner
    has_many :fee_payments, as: :owner

    # Effective scoped
    has_many :fees, -> { order(:id) }, inverse_of: :owner, as: :owner, class_name: 'Effective::Fee', dependent: :nullify
    accepts_nested_attributes_for :fees, reject_if: :all_blank, allow_destroy: true

    has_many :orders, -> { order(:id) }, inverse_of: :user, as: :user, class_name: 'Effective::Order', dependent: :nullify
    accepts_nested_attributes_for :orders, reject_if: :all_blank, allow_destroy: true

    has_one :membership, inverse_of: :owner, as: :owner, class_name: 'Effective::Membership'
    accepts_nested_attributes_for :membership

    has_many :membership_histories, -> { Effective::MembershipHistory.sorted }, inverse_of: :owner, as: :owner, class_name: 'Effective::MembershipHistory'
    accepts_nested_attributes_for :membership_histories

    effective_resource do
      timestamps
    end

    scope :members, -> { joins(:membership) }
  end

  def effective_memberships_owner
    self
  end

  def owner_label
    self.class.name.split('::').last
  end

  def membership_fees_paid?
    outstanding_fee_payment_fees.blank? && membership && membership.fees_paid?
  end

  def outstanding_fee_payment_fees
    fees.select { |fee| fee.fee_payment_fee? && !fee.purchased? }
  end

  def outstanding_fee_payment_orders
    orders.select { |order| order.parent_type.to_s.include?('FeePayment') && !order.purchased? }
  end

  def bad_standing_fees
    fees.select { |fee| fee.bad_standing? }
  end

  def max_fees_paid_period
    fees.select { |fee| fee.membership_period_fee? && fee.purchased? }.map(&:period).max
  end

  def max_fees_paid_through_period
    return nil if max_fees_paid_period.blank?
    EffectiveMemberships.Registrar.period_end_on(date: max_fees_paid_period)
  end

  def membership_removed?
    membership.blank? && membership_histories.any? { |history| history.removed? }
  end

  def membership_removed_on
    return nil unless membership_removed?
    membership_histories.find { |history| history.removed? }.start_on
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

    fee = fees.find { |fee| fee.fee_type == 'Prorated' && fee.period == period && fee.category == category } || fees.build()
    return fee if fee.purchased?

    fee.assign_attributes(
      fee_type: 'Prorated',
      category: category,
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

    fee = fees.find { |fee| fee.fee_type == 'Discount' && fee.period == period && fee.category == category } || fees.build()
    return fee if fee.purchased?

    fee.assign_attributes(
      fee_type: 'Discount',
      category: category,
      price: price,
      period: period
    )

    fee
  end

  def build_title_fee(period:, title:, fee_type: nil, category: nil, price: nil, qb_item_name: nil, tax_exempt: nil)
    fee_type ||= 'Renewal'

    fee = fees.find do |fee|
      fee.fee_type == fee_type && fee.period == period && fee.title == title &&
      (category.blank? || fee.category_id == category.id && fee.category_type == category.class.name)
    end

    return fee if fee&.purchased?

    # Build the title fee
    fee ||= fees.build()
    price ||= (category.renewal_fee.to_i if category.present? && fee_type == 'Renewal')

    fee.assign_attributes(
      fee_type: fee_type,
      title: title,
      category: category,
      price: price,
      period: period,
      qb_item_name: qb_item_name,
      tax_exempt: tax_exempt,
      late_on: nil,
      bad_standing_on: nil
    )
  end

  def build_renewal_fee(category:, period:, late_on:, bad_standing_on:)
    raise('must have an existing membership') unless membership.present?

    fee = fees.find { |fee| fee.fee_type == 'Renewal' && fee.period == period && fee.category_id == category.id && fee.category_type == category.class.name }
    return fee if fee&.purchased?

    # Build the renewal fee
    fee ||= fees.build()

    fee.assign_attributes(
      fee_type: 'Renewal',
      category: category,
      price: category.renewal_fee.to_i,
      period: period,
      late_on: late_on,
      bad_standing_on: bad_standing_on
    )

    fee
  end

  def build_late_fee(category:, period:)
    raise('must have an existing membership') unless membership.present?

    # Return existing but do not build yet
    fee = fees.find { |fee| fee.fee_type == 'Late' && fee.period == period && fee.category_id == category.id && fee.category_type == category.class.name }
    return fee if fee&.purchased?

    # Only continue if there is a late renewal fee for the same period
    renewal_fee = fees.find { |fee| fee.fee_type == 'Renewal' && fee.period == period && fee.category_id == category.id && fee.category_type == category.class.name }
    return unless fee.present? || renewal_fee&.late?

    # Build the late fee
    fee ||= fees.build()

    fee.assign_attributes(
      fee_type: 'Late',
      category: category,
      price: category.late_fee.to_i,
      period: period,
    )

    fee
  end

  def update_membership_status!
    raise('expected membership to be present') unless membership.present?

    # Assign fees paid through period
    membership.fees_paid_period = max_fees_paid_period()
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
    end

    save!
  end

  def build_membership_history(start_on: nil)
    raise('expected membership to be present') unless membership.present?

    # The date of change
    start_on ||= Time.zone.now
    removed = membership.marked_for_destruction?

    # End the other membership histories
    membership_histories.each { |history| history.end_on ||= start_on }

    # Snapshot of the current membership at this time
    membership_histories.build(
      start_on: start_on,
      end_on: nil,
      removed: removed,
      bad_standing: membership.bad_standing?,
      categories: (membership.categories.map(&:to_s) unless removed),
      category_ids: (membership.categories.map(&:id) unless removed),
      number: (membership.number unless removed)
    )
  end

  def membership_history_on(date)
    raise('expected a date') unless date.respond_to?(:strftime)
    membership_histories.find { |history| (history.start_on..history.end_on).cover?(date) } # Ruby 2.6 supports endless ranges
  end

end
