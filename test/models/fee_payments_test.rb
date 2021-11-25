require 'test_helper'

class FeePaymentsTest < ActiveSupport::TestCase

  test 'fee payments are valid' do
    membership_category ||= Effective::MembershipCategory.where(title: 'Full Member').first!
    user = build_user_with_address()

    EffectiveMemberships.Registrar.register!(user, to: membership_category)

    assert_equal 1, user.fees.length
    assert user.fees.all? { |fee| !fee.purchased? }

    fp = EffectiveMemberships.FeePayment.new(user: user)
    fp.ready!
    assert fp.draft?
    assert_equal user.fees, fp.fees

    fp.submit_order.purchase!
    fp.reload
    assert_equal user.fees, fp.submit_order.purchasables

    assert fp.submitted?
    assert fp.was_submitted?
    assert fp.submit_order.purchased?

    user.reload
    assert_equal 1, user.fees.length
    assert user.fees.all? { |fee| fee.purchased? }
  end

  test 'fee payments update users status' do
    membership_category ||= Effective::MembershipCategory.where(title: 'Full Member').first!
    user = build_user_with_address()

    EffectiveMemberships.Registrar.register!(user, to: membership_category)

    assert user.membership.fees_paid_through_period.blank?

    fp = EffectiveMemberships.FeePayment.new(user: user)
    fp.ready!
    fp.submit_order.purchase!

    user.reload
    assert user.membership.fees_paid_through_period.present?
    assert_equal EffectiveMemberships.Registrar.current_period, user.membership.fees_paid_through_period
  end

end
