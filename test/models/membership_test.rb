require 'test_helper'
require 'timecop'

class MembershipTest < ActiveSupport::TestCase

  test 'number_as_integer is assigned' do
    owner = build_member()
    membership = owner.membership

    assert membership.number.present?
    assert membership.number_as_integer.present?

    membership.update!(number: 'asdf')
    assert_equal 'asdf', membership.number
    assert membership.number_as_integer.nil?

    membership.update!(number: '123')
    assert_equal '123', membership.number
    assert_equal 123, membership.number_as_integer
  end

  test 'revising a membership to previous fees paid period creates renewal fees for current period' do
    owner = build_member()
    membership = owner.membership

    current_period = EffectiveMemberships.Registrar.current_period

    assert_equal membership.fees_paid_period, current_period
    assert membership.fees_paid?
    assert membership.paid_fees_through?
    refute membership.unpaid_fees_through?

    membership.owner.fees.delete_all
    assert_equal 0, membership.owner.fees.length

    with_time_travel(current_period) do
      membership.assign_attributes(joined_on: membership.joined_on - 1.year, fees_paid_period: membership.fees_paid_period - 1.year)
      refute membership.paid_fees_through?
      assert membership.unpaid_fees_through?

      membership.revise!
    end

    assert_equal 1, membership.owner.fees.length
    assert_equal 'Renewal', membership.owner.fees.first.fee_type
  end

  test 'revising a membership to blank fees paid period creates renewal fees for current period' do
    owner = build_member()
    membership = owner.membership

    current_period = EffectiveMemberships.Registrar.current_period

    assert_equal membership.fees_paid_period, current_period
    assert membership.fees_paid?
    assert membership.paid_fees_through?
    refute membership.unpaid_fees_through?

    membership.owner.fees.delete_all

    with_time_travel(current_period) do
      membership.assign_attributes(joined_on: membership.joined_on - 1.year, fees_paid_period: nil)
      refute membership.paid_fees_through?
      assert membership.unpaid_fees_through?

      membership.revise!
    end

    assert_equal 1, membership.owner.fees.length
    assert_equal 'Renewal', membership.owner.fees.first.fee_type
  end

  test 'revising a membership to previous fees paid period creates renewal fees and late fees for current period' do
    owner = build_member()
    membership = owner.membership

    current_period = EffectiveMemberships.Registrar.current_period
    late_fee_date = EffectiveMemberships.Registrar.late_fee_date(period: current_period)

    assert_equal membership.fees_paid_period, current_period
    assert membership.fees_paid?
    assert membership.paid_fees_through?
    refute membership.unpaid_fees_through?

    membership.owner.fees.delete_all
    assert_equal 0, membership.owner.fees.length

    with_time_travel(late_fee_date) do
      membership.assign_attributes(joined_on: membership.joined_on - 1.year, fees_paid_period: membership.fees_paid_period - 1.year)
      refute membership.paid_fees_through?
      assert membership.unpaid_fees_through?

      membership.revise!
    end

    assert_equal 2, membership.owner.fees.length
    assert_equal 'Renewal', membership.owner.fees.first.fee_type
    assert_equal 'Late', membership.owner.fees.last.fee_type
  end

end
