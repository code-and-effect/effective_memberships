require 'test_helper'

class FeePaymentsTest < ActiveSupport::TestCase

  test 'fee payments are valid' do
    category ||= Effective::Category.where(title: 'Full Member').first!
    user = build_user_with_address()

    EffectiveMemberships.Registrar.register!(user, to: category)

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
    category ||= Effective::Category.where(title: 'Full Member').first!
    user = build_user_with_address()

    EffectiveMemberships.Registrar.register!(user, to: category)

    assert user.membership.fees_paid_period.blank?
    assert user.membership.fees_paid_through_period.blank?

    fp = EffectiveMemberships.FeePayment.new(user: user)
    fp.ready!
    fp.submit_order.purchase!

    user.reload
    assert user.membership.fees_paid_period.present?
    assert user.membership.fees_paid_through_period.present?
    assert_equal EffectiveMemberships.Registrar.current_period, user.membership.fees_paid_period
    assert_equal EffectiveMemberships.Registrar.current_period.end_of_year, user.membership.fees_paid_through_period
  end

  test 'fee payments updates bad standing' do
    user = build_member()

    user.membership.update!(bad_standing: true, bad_standing_reason: "Late Fees", fees_paid_period: nil, fees_paid_through_period: nil)
    user.fees.each { |fee| fee.update_column(:purchased_order_id, nil) }

    fp = EffectiveMemberships.FeePayment.new(user: user)
    fp.ready!
    fp.submit_order.purchase!

    user.reload

    assert user.membership.fees_paid_period.present?
    assert user.membership.fees_paid_through_period.present?

    refute user.membership.bad_standing?
    assert user.membership.good_standing?
  end

end
