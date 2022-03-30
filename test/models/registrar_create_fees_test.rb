require 'test_helper'

class RegistrarCreateFeesTest < ActiveSupport::TestCase
  test 'create fees for current members' do
    3.times { build_member() }

    period = EffectiveMemberships.Registrar.current_period

    assert_equal 3, User.members.count
    assert_equal 3, Effective::Membership.count
    assert_equal 3, Effective::Membership.where(fees_paid_period: period).count

    assert_equal 0, Effective::Membership.with_unpaid_fees_through.count
    assert_equal 0, Effective::Membership.with_unpaid_fees_through(period).count

    EffectiveMemberships.Registrar.create_fees!
    assert_equal 0, Effective::Fee.where(category: 'Renewal').count
    assert_equal 0, Effective::Fee.where(category: 'Late').count
  end

  test 'create fees for outstanding fees members' do
    3.times { build_member() }

    period = EffectiveMemberships.Registrar.current_period
    last_period = EffectiveMemberships.Registrar.period(date: Time.zone.now - 1.year)
    refute_equal period, last_period

    # Now everyone is a outstanding member.
    Effective::Membership.update_all(fees_paid_period: last_period)
    Effective::Fee.update_all(period: last_period)

    # Create Fees for this period scopes
    assert_equal 3, Effective::Membership.with_unpaid_fees_through.count
    assert_equal 3, Effective::Membership.with_unpaid_fees_through(period).count

    # There are no Renewal fees so far
    assert_equal 0, Effective::Fee.where(fee_type: 'Renewal').count

    EffectiveMemberships.Registrar.create_fees!
    assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count
    assert_equal 3, Effective::Fee.pluck(:owner_id).uniq.length

    # Running it a second time makes no changes
    EffectiveMemberships.Registrar.create_fees!
    assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count
    assert_equal 3, Effective::Fee.pluck(:owner_id).uniq.length
  end

  test 'create fees for late members' do
    3.times { build_member() }
    last_period = EffectiveMemberships.Registrar.period(date: Time.zone.now - 1.year)

    # Now everyone is a outstanding member.
    Effective::Membership.update_all(fees_paid_period: last_period)
    Effective::Fee.update_all(period: last_period)

    # Create Renewal Fees
    EffectiveMemberships.Registrar.create_fees!(late_on: Time.zone.now + 1.day)
    EffectiveMemberships.Registrar.create_fees!(late_on: Time.zone.now + 1.day)
    assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count

    fee = Effective::Fee.where(fee_type: 'Renewal').first
    refute fee.late?

    assert_equal 0, Effective::Fee.where(fee_type: 'Late').count

    # Update The Renewal Fees so they're all late
    Effective::Fee.where(fee_type: 'Renewal').update_all(late_on: Time.zone.now - 1.day)

    # Create Late Fees
    EffectiveMemberships.Registrar.create_fees!(late_on: Time.zone.now - 1.day)
    assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count
    assert_equal 3, Effective::Fee.where(fee_type: 'Late').count

    # Running it a second time makes no changes
    EffectiveMemberships.Registrar.create_fees!(late_on: Time.zone.now - 1.day)
    assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count
    assert_equal 3, Effective::Fee.where(fee_type: 'Late').count
  end

  test 'create fees assigns bad standing' do
    3.times { build_member() }
    last_period = EffectiveMemberships.Registrar.period(date: Time.zone.now - 1.year)

    # Now everyone is a outstanding member.
    # No one is in bad standing
    Effective::Membership.update_all(fees_paid_period: last_period)
    Effective::Fee.update_all(period: last_period)
    assert_equal 0, Effective::Membership.where(bad_standing: true).count

    # Create Renewal Fees
    EffectiveMemberships.Registrar.create_fees!(bad_standing_on: Time.zone.now + 1.day)
    assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count

    fee = Effective::Fee.where(fee_type: 'Renewal').first
    refute fee.bad_standing?

    # Update The Renewal Fees so they're all in bad standing
    Effective::Fee.where(fee_type: 'Renewal').update_all(bad_standing_on: Time.zone.now - 1.minute)
    assert_equal 0, Effective::Membership.where(bad_standing: true).count

    # Create Fees Should mark them in bad standing
    EffectiveMemberships.Registrar.create_fees!(bad_standing_on: Time.zone.now - 1.minute)
    assert_equal 3, Effective::Membership.where(bad_standing: true).count

    # Running it a second time makes no changes
    EffectiveMemberships.Registrar.create_fees!
    assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count
  end

end
