require 'test_helper'
require 'timecop'

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
    Effective::Membership.update_all(fees_paid_period: last_period, joined_on: last_period - 1.day)
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

    current_period = EffectiveMemberships.Registrar.current_period
    last_period = EffectiveMemberships.Registrar.last_period
    late_fee_date = EffectiveMemberships.Registrar.late_fee_date(period: current_period)

    # Now everyone is a member that paid previously
    Effective::Membership.update_all(fees_paid_period: last_period, joined_on: last_period - 1.day)
    Effective::Fee.update_all(period: last_period)

    # Create Renewal Fees
    with_time_travel(current_period + 1.day) do
      EffectiveMemberships.Registrar.create_fees!
      EffectiveMemberships.Registrar.create_fees!

      assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count

      fee = Effective::Fee.where(fee_type: 'Renewal').first
      refute fee.late?

      assert_equal 0, Effective::Fee.where(fee_type: 'Late').count
    end

    # Go to a time where we are late
    with_time_travel(late_fee_date) do
      # Create Late Fees
      EffectiveMemberships.Registrar.create_fees!
      assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count
      assert_equal 3, Effective::Fee.where(fee_type: 'Late').count

      # Running it a second time makes no changes
      EffectiveMemberships.Registrar.create_fees!
      assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count
      assert_equal 3, Effective::Fee.where(fee_type: 'Late').count
    end

  end

  test 'create fees assigns bad standing' do
    3.times { build_member() }

    current_period = EffectiveMemberships.Registrar.current_period
    last_period = EffectiveMemberships.Registrar.last_period
    bad_standing_date = EffectiveMemberships.Registrar.bad_standing_date(period: current_period)

    Effective::Category.update_all(create_bad_standing: true)

    # Now everyone is a member that paid previously
    # No one is in bad standing
    Effective::Membership.update_all(fees_paid_period: last_period, joined_on: last_period - 1.day)
    Effective::Fee.update_all(period: last_period)
    assert_equal 0, Effective::Membership.where(bad_standing: true).count

    # Create Renewal Fees
    with_time_travel(current_period + 1.day) do
      EffectiveMemberships.Registrar.create_fees!
      assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count

      fee = Effective::Fee.where(fee_type: 'Renewal').first
      refute fee.bad_standing?
    end

    # Go to a time where we are bad standing
    with_time_travel(bad_standing_date) do
      # Create Fees Should mark them in bad standing
      EffectiveMemberships.Registrar.create_fees!
      assert_equal 3, Effective::Membership.where(bad_standing: true).count

      # Running it a second time makes no changes
      EffectiveMemberships.Registrar.create_fees!
      assert_equal 3, Effective::Fee.where(fee_type: 'Renewal').count

      # Members are all in bad standing
      Effective::Membership.where(bad_standing: true).each do |membership|
        assert membership.bad_standing?
      end
    end

  end

end
