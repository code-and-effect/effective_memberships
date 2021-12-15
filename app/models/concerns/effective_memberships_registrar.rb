# frozen_string_literal: true

# EffectiveMembershipsRegistrar
#
# This is different cause its not an ActiveRecord one
#
# Mark your registrar with include EffectiveMembershipsRegistrar
#
# Mark your category model with effective_memberships_category to get all the includes

module EffectiveMembershipsRegistrar
  extend ActiveSupport::Concern

  module ClassMethods
    def effective_memberships_registrar?; true; end
  end

  included do
  end

  def renewal_fee_date(date:)
    Date.new(date.year, 12, 1) # Fees roll over every December 1st
    raise('to be implemented by app registrar')
  end

  def late_fee_date(period:)
    Date.new(period.year, 2, 1) # Fees are late after February 1st
    raise('to be implemented by app registrar')
  end

  def bad_standing_date(period:)
    Date.new(period.year, 3, 1) # Membership in bad standing after March 1st
    raise('to be implemented by app registrar')
  end

  def register!(owner, to:, date: nil, number: nil, skip_fees: false)
    raise('expecting a memberships owner') unless owner.class.respond_to?(:effective_memberships_owner?)
    raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)
    raise('owner has existing membership. use reclassify! instead.') if owner.membership.present?

    # Default Date and next number
    date ||= Time.zone.now
    number = next_membership_number(owner, to: to) if number.blank?
    period = period(date: date)
    period_end_on = period_end_on(date: date)

    # Build a membership
    membership = owner.build_membership

    # Assign Category
    membership.build_membership_category(category: to)

    # Assign Dates
    membership.joined_on ||= date  # Only if not already present
    membership.registration_on = date  # Always new registration_on

    # Assign Number
    membership.number = number
    membership.number_as_integer = (Integer(number) rescue nil)

    # Assign fees paid through period
    if skip_fees
      membership.fees_paid_period = period
      membership.fees_paid_through_period = period_end_on
    end

    # Or, Build Fees
    unless skip_fees
      fee = owner.build_prorated_fee(date: date)
      raise('already has purchased prorated fee') if fee.purchased?
    end

    # Save owner
    save!(owner, date: date)
  end

  def reclassify!(owner, to:, date: nil, skip_fees: false)
    raise('expecting a memberships owner') unless owner.class.respond_to?(:effective_memberships_owner?)
    raise('owner must have an existing membership. use register! instead') if owner.membership.blank?

    # Todo. I dunno this was owner.membership.category
    from = owner.membership.category

    raise('expecting a to memberships category') unless to.class.respond_to?(:effective_memberships_category?)
    raise('expecting a from memberships category') unless from.class.respond_to?(:effective_memberships_category?)
    raise('expected to and from to be different') if from == to

    raise('todo')

    date ||= Time.zone.now

    membership = owner.membership

    membership.category = to
    membership.registration_on = date

    unless skip_fees
      fee = owner.build_prorated_fee(date: date)
      raise('already has purchased prorated fee') if fee.purchased?

      fee = owner.build_discount_fee(date: date, from: from)
      raise('already has purchased discount fee') if fee.purchased?
    end

    save!(owner, date: date)
  end

  def remove!(owner, date: nil)
    raise('expecting a memberships owner') unless owner.class.respond_to?(:effective_memberships_owner?)
    raise('expected a member') unless owner.membership.present?

    # Date
    date ||= Time.zone.now

    # Remove Membership
    owner.membership.mark_for_destruction

    # Delete unpurchased fees and orders
    owner.outstanding_fee_payment_fees.each { |fee| fee.mark_for_destruction }
    owner.outstanding_fee_payment_orders.each { |order| order.mark_for_destruction }

    save!(owner, date: date)
  end

  def bad_standing!(owner, reason:, date: nil)
    raise('expecting a memberships owner') unless owner.class.respond_to?(:effective_memberships_owner?)
    raise('expected a member') unless owner.membership.present?
    raise('expected owner to be in good standing') if owner.membership.bad_standing?

    # Date
    date ||= Time.zone.now
    membership = owner.membership

    membership.bad_standing = true
    membership.bad_standing_admin = true
    membership.bad_standing_reason = reason

    save!(owner, date: date)
  end

  def good_standing!(owner, date: nil)
    raise('expecting a memberships owner') unless owner.class.respond_to?(:effective_memberships_owner?)
    raise('expected a member') unless owner.membership.present?
    raise('expected owner to be in bad standing') unless owner.membership.bad_standing?

    # Date
    date ||= Time.zone.now
    membership = owner.membership

    membership.bad_standing = false
    membership.bad_standing_admin = false
    membership.bad_standing_reason = nil

    save!(owner, date: date)
  end

  def fees_paid!(owner, date: nil)
    raise('expecting a memberships owner') unless owner.class.respond_to?(:effective_memberships_owner?)
    raise('expected a member') unless owner.membership.present?

    # Date
    date ||= Time.zone.now

    period = period(date: date)
    period_end_on = period_end_on(date: date)

    if owner.outstanding_fee_payment_fees.present?
      fp = EffectiveMemberships.FeePayment.new(owner: owner)
      fp.ready!
      fp.submit_order.purchase!(skip_buyer_validations: true, email: false)
    end

    owner.membership.update!(fees_paid_period: period, fees_paid_through_period: period_end_on)
  end

  def next_membership_number(owner, to:)
    raise('expecting a memberships owner') unless owner.class.respond_to?(:effective_memberships_owner?)
    raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)

    # Just a simple number right now
    number = (Effective::Membership.all.max_number || 0) + 1

    # Returns a string
    number.to_s
  end

  def current_period
    period(date: Time.zone.now)
  end

  # Returns a date of Jan 1, Year
  def period(date:)
    cutoff = renewal_fee_date(date: date) # period_end_on
    period = (date < cutoff) ? date.beginning_of_year : date.advance(years: 1).beginning_of_year
    period.to_date
  end

  def period_end_on(date:)
    period(date: date).end_of_year
  end

  # This is intended to be run once per day in a rake task
  # Create Renewal and Late fees
  def create_fees!(period: nil, late_on: nil, bad_standing_on: nil)
    # The current period, based on Time.zone.now
    period ||= current_period
    late_on ||= late_fee_date(period: period)
    bad_standing_on ||= bad_standing_date(period: period)

    # Create Renewal Fees
    Effective::Membership.create_renewal_fees(period).find_each do |membership|
      fee = membership.owner.build_renewal_fee(period: period, late_on: late_on, bad_standing_on: bad_standing_on)
      raise("expected build_renewal_fee to return a fee for period #{period}") unless fee.kind_of?(Effective::Fee)
      next if fee.purchased?

      fee.save!
    end

    GC.start

    # Create Late Fees
    Effective::Membership.create_late_fees(period).find_each do |membership|
      fee = membership.owner.build_late_fee(period: period)
      next if fee.blank? || fee.purchased?

      fee.save!
    end

    GC.start

    # Update Membership Status - Assign In Bad Standing
    Effective::Membership.deep.with_unpaid_fees_through(period).find_each do |membership|
      membership.owner.update_membership_status!
    end

    true
  end

  # Called in the after_purchase of fee payment
  def fee_payment_purchased!(owner)
    raise('expecting a memberships owner') unless owner.class.respond_to?(:effective_memberships_owner?)
    owner.update_membership_status!
  end

  protected

  def save!(owner, date: Time.zone.now)
    owner.build_membership_history(start_on: date)
    owner.save!
  end

end
