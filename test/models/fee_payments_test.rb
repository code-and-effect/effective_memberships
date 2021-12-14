require 'test_helper'

class FeePaymentsTest < ActiveSupport::TestCase

  test 'fee payments are valid' do
    membership_category ||= Effective::MembershipCategory.where(title: 'Full Member').first!
    owner = build_user_with_address()

    EffectiveMemberships.Registrar.register!(owner, to: membership_category)

    assert_equal 1, owner.fees.length
    assert owner.fees.all? { |fee| !fee.purchased? }

    fp = EffectiveMemberships.FeePayment.new(owner: owner)
    fp.ready!
    assert fp.draft?
    assert_equal owner.fees, fp.fees

    fp.submit_order.purchase!
    fp.reload
    assert_equal owner.fees, fp.submit_order.purchasables

    assert fp.submitted?
    assert fp.was_submitted?
    assert fp.submit_order.purchased?

    owner.reload
    assert_equal 1, owner.fees.length
    assert owner.fees.all? { |fee| fee.purchased? }
  end

  test 'fee payments update users status' do
    membership_category ||= Effective::MembershipCategory.where(title: 'Full Member').first!
    owner = build_user_with_address()

    EffectiveMemberships.Registrar.register!(owner, to: membership_category)

    assert owner.membership.fees_paid_period.blank?
    assert owner.membership.fees_paid_through_period.blank?

    fp = EffectiveMemberships.FeePayment.new(owner: owner)
    fp.ready!
    fp.submit_order.purchase!

    owner.reload
    assert owner.membership.fees_paid_period.present?
    assert owner.membership.fees_paid_through_period.present?
    assert_equal EffectiveMemberships.Registrar.current_period, owner.membership.fees_paid_period
    assert_equal EffectiveMemberships.Registrar.current_period.end_of_year, owner.membership.fees_paid_through_period
  end

  test 'fee payments updates bad standing' do
    owner = build_member()

    owner.membership.update!(bad_standing: true, bad_standing_reason: "Late Fees", fees_paid_period: nil, fees_paid_through_period: nil)
    owner.fees.each { |fee| fee.update_column(:purchased_order_id, nil) }

    fp = EffectiveMemberships.FeePayment.new(owner: owner)
    fp.ready!
    fp.submit_order.purchase!

    owner.reload

    assert owner.membership.fees_paid_period.present?
    assert owner.membership.fees_paid_through_period.present?

    refute owner.membership.bad_standing?
    assert owner.membership.good_standing?
  end

end
