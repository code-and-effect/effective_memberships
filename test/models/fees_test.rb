require 'test_helper'

class FeesTest < ActiveSupport::TestCase

  test 'build prorated fee' do
    now = Time.zone.now
    period = EffectiveMemberships.Registrar.current_period

    category = EffectiveMemberships.Category.first
    category.update!("prorated_#{now.strftime('%b').downcase}" => 123_00)

    owner = build_user()
    membership = owner.build_membership
    membership.build_membership_category(category: category)
    membership.joined_on = now
    membership.number = 1

    # Build the fee
    fee = owner.build_prorated_fee(date: now)

    assert_equal 'Prorated', fee.fee_type
    assert_equal 123_00, fee.price
    assert_equal category, fee.category
    assert_equal period, fee.period
    assert fee.late_on.blank?
    assert fee.bad_standing_on.blank?

    assert fee.save!

    # Now see if it's indempotent
    fee2 = owner.build_prorated_fee(date: now)
    assert_equal fee, fee2

    owner.reload
    fee3 = owner.build_prorated_fee(date: now)
    assert_equal fee, fee3
  end

  test 'build renewal fee' do
    owner = build_member(date: EffectiveMemberships.Registrar.last_period)
    category = owner.membership.category

    now = Time.zone.now
    period = EffectiveMemberships.Registrar.current_period
    late_on = EffectiveMemberships.Registrar.late_fee_date(period: period)
    bad_standing_on = EffectiveMemberships.Registrar.bad_standing_date(period: period)

    # Build the fee
    fee = owner.build_renewal_fee(category: category, period: period, late_on: late_on, bad_standing_on: bad_standing_on)

    assert_equal 'Renewal', fee.fee_type
    assert_equal category.renewal_fee, fee.price
    assert_equal category, fee.category
    assert_equal period, fee.period
    assert_equal late_on, fee.late_on
    assert_equal bad_standing_on, fee.bad_standing_on

    assert fee.save!

    # Now see if it's indempotent
    fee2 = owner.build_renewal_fee(category: category, period: period, late_on: late_on, bad_standing_on: bad_standing_on)
    assert_equal fee, fee2

    owner.reload
    fee3 = owner.build_renewal_fee(category: category, period: period, late_on: late_on, bad_standing_on: bad_standing_on)
    assert_equal fee, fee3
  end

  test 'building a renewal year in the same year as a prorated raises an error' do
    owner = build_member()
    category = owner.membership.category

    now = Time.zone.now
    period = EffectiveMemberships.Registrar.current_period
    late_on = EffectiveMemberships.Registrar.late_fee_date(period: period)
    bad_standing_on = EffectiveMemberships.Registrar.bad_standing_date(period: period)

    # Assert a prorated fee exists for this category
    existing = owner.membership_period_fee(category: category, period: period)
    assert existing.present?
    assert_equal 'Prorated', existing.fee_type

    # Build the fee
    retval = begin
      owner.build_renewal_fee(category: category, period: period, late_on: late_on, bad_standing_on: bad_standing_on)
    rescue => e
      e.message
    end

    assert_equal 'must not have an existing membership_period (prorated) fee in this period', retval
  end

  test 'build late fee' do
    owner = build_member(date: EffectiveMemberships.Registrar.last_period)
    category = owner.membership.category

    now = Time.zone.now
    period = EffectiveMemberships.Registrar.current_period
    late_on = EffectiveMemberships.Registrar.late_fee_date(period: period)
    bad_standing_on = EffectiveMemberships.Registrar.bad_standing_date(period: period)

    # Try to build late fee
    fee = owner.build_late_fee(category: category, period: period)
    assert fee.blank? # No existing renewal fee

    # Create a renewal fee
    fee = owner.build_renewal_fee(category: category, period: period, late_on: now - 1.second, bad_standing_on: bad_standing_on)
    assert fee.late?

    # Build late fee again
    fee = owner.build_late_fee(category: category, period: period)
    assert fee.present?

    assert_equal 'Late', fee.fee_type
    assert_equal category.late_fee, fee.price
    assert_equal category, fee.category
    assert_equal period, fee.period
    assert fee.late_on.blank?
    assert fee.bad_standing_on.blank?

    assert fee.save!

    # Now see if it's indempotent
    fee2 = owner.build_late_fee(category: category, period: period)
    assert_equal fee, fee2

    owner.reload
    fee3 = owner.build_late_fee(category: category, period: period)
    assert_equal fee, fee3
  end

  test 'build discount fee' do
    owner = build_member()

    now = Time.zone.now
    period = EffectiveMemberships.Registrar.current_period

    to = owner.membership.category
    from = EffectiveMemberships.Category.where.not(id: owner.membership.category_id).first!

    to.update!("prorated_#{now.strftime('%b').downcase}" => 100_00)
    from.update!("prorated_#{now.strftime('%b').downcase}" => 75_00)

    # Build discount fee
    fee = owner.build_discount_fee(from: from)

    assert_equal 'Discount', fee.fee_type
    assert_equal -75_00, fee.price
    assert_equal to, fee.category
    assert_equal period, fee.period

    assert fee.save!

    # Now see if it's indempotent
    fee2 = owner.build_discount_fee(from: from)
    assert_equal fee, fee2

    owner.reload
    fee3 = owner.build_discount_fee(from: from)
    assert_equal fee, fee3
  end

end
