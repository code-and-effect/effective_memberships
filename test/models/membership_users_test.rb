require 'test_helper'

class MembershipUsersTest < ActiveSupport::TestCase

  test 'build_user is valid' do
    assert build_user().valid?
  end

  test 'build_member is valid' do
    user = build_member()

    today = Time.zone.now.to_date
    current_period = EffectiveMemberships.Registrar.current_period

    assert user.membership.present?
    assert user.membership.category.present?
    assert user.membership.number.present?
    assert_equal today, user.membership.joined_on
    assert_equal today, user.membership.registration_on

    assert_equal 1, user.fees.length

    fee = user.fees.find { |fee| fee.category == 'Prorated' && fee.purchased? }
    assert fee.present?, 'expected a purchased prorated fee'

    assert user.membership.fees_paid_period.present?
    assert_equal user.membership.fees_paid_period, fee.period
    assert_equal user.membership.fees_paid_period, current_period

    assert user.membership.fees_paid_through_period.present?
    assert_equal user.membership.fees_paid_through_period, fee.period.end_of_year
    assert_equal user.membership.fees_paid_through_period, current_period.end_of_year
  end

end
