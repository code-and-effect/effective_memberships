require 'test_helper'

class FeesTest < ActiveSupport::TestCase

  test 'build prorated fee' do
    now = Time.zone.now
    period = EffectiveMemberships.Registrar.current_period

    category = EffectiveMemberships.MembershipCategory.first
    category.update!("prorated_#{now.strftime('%b').downcase}" => 123_00)

    user = build_user()
    membership = user.build_membership
    membership.category = category
    membership.joined_on = now
    membership.number = 1

    # Build the fee
    fee = user.build_prorated_fee(date: now)

    assert_equal 'Prorated', fee.category
    assert_equal 123_00, fee.price
    assert_equal category, fee.membership_category
    assert_equal period, fee.period
    assert fee.late_on.blank?
    assert fee.bad_standing_on.blank?

    assert fee.save!

    # Now see if it's indempotent
    fee2 = user.build_prorated_fee(date: now)
    assert_equal fee, fee2

    user.reload
    fee3 = user.build_prorated_fee(date: now)
    assert_equal fee, fee3
  end

  test 'build renewal fee' do
    user = build_member()
    category = user.membership.category

    now = Time.zone.now
    period = EffectiveMemberships.Registrar.current_period
    late_on = EffectiveMemberships.Registrar.late_fee_date(period: period)
    bad_standing_on = EffectiveMemberships.Registrar.bad_standing_date(period: period)

    # Build the fee
    fee = user.build_renewal_fee(period: period, late_on: late_on, bad_standing_on: bad_standing_on)

    assert_equal 'Renewal', fee.category
    assert_equal category.renewal_fee, fee.price
    assert_equal category, fee.membership_category
    assert_equal period, fee.period
    assert_equal late_on, fee.late_on
    assert_equal bad_standing_on, fee.bad_standing_on

    assert fee.save!

    # Now see if it's indempotent
    fee2 = user.build_renewal_fee(period: period, late_on: late_on, bad_standing_on: bad_standing_on)
    assert_equal fee, fee2

    user.reload
    fee3 = user.build_renewal_fee(period: period, late_on: late_on, bad_standing_on: bad_standing_on)
    assert_equal fee, fee3
  end

  test 'build late fee' do
    user = build_member()
    category = user.membership.category

    now = Time.zone.now
    period = EffectiveMemberships.Registrar.current_period
    late_on = EffectiveMemberships.Registrar.late_fee_date(period: period)
    bad_standing_on = EffectiveMemberships.Registrar.bad_standing_date(period: period)

    # Try to build late fee
    fee = user.build_late_fee(period: period)
    assert fee.blank? # No existing renewal fee

    # Create a renewal fee
    fee = user.build_renewal_fee(period: period, late_on: now - 1.second, bad_standing_on: bad_standing_on)
    assert fee.late?

    # Build late fee again
    fee = user.build_late_fee(period: period)
    assert fee.present?

    assert_equal 'Late', fee.category
    assert_equal category.late_fee, fee.price
    assert_equal category, fee.membership_category
    assert_equal period, fee.period
    assert fee.late_on.blank?
    assert fee.bad_standing_on.blank?

    assert fee.save!

    # Now see if it's indempotent
    fee2 = user.build_late_fee(period: period)
    assert_equal fee, fee2

    user.reload
    fee3 = user.build_late_fee(period: period)
    assert_equal fee, fee3
  end

end
