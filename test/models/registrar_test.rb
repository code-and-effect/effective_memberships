require 'test_helper'

class RegistrarTest < ActiveSupport::TestCase
  test 'register' do
    user = build_user()
    category = EffectiveMemberships.MembershipCategory.first

    refute user.membership.present?
    assert_equal 0, user.fees.length

    next_number = EffectiveMemberships.Registrar.next_membership_number(user, to: category)
    assert EffectiveMemberships.Registrar.register!(user, to: category)

    assert user.membership.present?
    assert_equal next_number, user.membership.number

    assert_equal 1, user.fees.length
    assert user.fees.find { |fee| fee.category == 'Prorated' }
  end

  test 'register with skip_fees' do
    user = build_user()
    category = EffectiveMemberships.MembershipCategory.first

    refute user.membership.present?
    assert_equal 0, user.fees.length

    next_number = EffectiveMemberships.Registrar.next_membership_number(user, to: category)
    assert EffectiveMemberships.Registrar.register!(user, to: category, skip_fees: true)

    assert user.membership.present?
    assert_equal next_number, user.membership.number

    assert_equal 0, user.fees.length
    assert user.membership.fees_paid_through_period.present?
  end

  test 'reclassify' do
    user = build_member()
    user.fees.delete_all

    from = user.membership.category
    to = EffectiveMemberships.MembershipCategory.where.not(id: from.id).first!

    assert EffectiveMemberships.Registrar.reclassify!(user, to: to)

    assert_equal to, user.membership.category

    assert_equal 2, user.fees.length
    assert user.fees.find { |fee| fee.category == 'Prorated' }
    assert user.fees.find { |fee| fee.category == 'Discount' }
  end

  test 'bad standing' do
    user = build_member()
    refute user.membership.bad_standing?

    assert EffectiveMemberships.Registrar.bad_standing!(user, reason: 'you know')

    assert user.membership.bad_standing?
    assert user.membership.bad_standing_admin?
    assert_equal 'you know', user.membership.bad_standing_reason
  end

  test 'good standing' do
    user = build_member()
    user.membership.update!(bad_standing: true, bad_standing_admin: true, bad_standing_reason: 'you know')
    assert user.membership.bad_standing?

    assert EffectiveMemberships.Registrar.good_standing!(user)

    refute user.membership.bad_standing?
    refute user.membership.bad_standing_admin?
    assert user.membership.bad_standing_reason.blank?
  end

  test 'fees paid' do
    user = build_user()
    membership_category ||= Effective::MembershipCategory.where(title: 'Full Member').first!
    period = EffectiveMemberships.Registrar.current_period

    EffectiveMemberships.Registrar.register!(user, to: membership_category)

    assert_equal 1, user.outstanding_fee_payment_fees.length
    assert user.membership.present?
    assert user.membership.fees_paid_through_period.blank?

    assert EffectiveMemberships.Registrar.fees_paid!(user)

    assert_equal 0, user.outstanding_fee_payment_fees.length
    assert_equal period, user.membership.fees_paid_through_period
  end

  test 'remove' do
    user = build_member()
    date = Time.zone.now + 1.year

    # Create unpurchased fees
    user.build_renewal_fee(period: date, late_on: date, bad_standing_on: date)
    user.save!

    # Create unpurchased order
    fp = EffectiveMemberships.FeePayment.new(user: user)
    fp.ready!

    # User is a member with outstanding fees and orders
    assert user.membership.present?
    assert user.outstanding_fee_payment_fees.present?
    assert user.orders.select { |order| order.purchased? == false }.present?

    refute user.membership_removed?
    refute user.membership_histories.any? { |history| history.removed? }

    assert EffectiveMemberships.Registrar.remove!(user)
    user.reload
    user.membership_histories.reload

    # User is removed and outstanding fees and orders deleted
    assert user.membership.blank?
    assert user.outstanding_fee_payment_fees.blank?
    assert user.orders.select { |order| order.purchased? == false }.blank?

    # Membership history
    history = user.membership_histories.last

    assert history.removed?
    assert history.membership_category.blank?
    assert history.number.blank?

    assert user.membership_removed?
    assert_equal Time.zone.now.to_date, user.membership_removed_on
  end

end
