require 'test_helper'

class RegistrarTest < ActiveSupport::TestCase
  test 'register' do
    owner = build_user()
    category = EffectiveMemberships.MembershipCategory.first

    refute owner.membership.present?
    assert_equal 0, owner.fees.length

    next_number = EffectiveMemberships.Registrar.next_membership_number(owner, to: category)
    assert EffectiveMemberships.Registrar.register!(owner, to: category)

    assert owner.membership.present?
    assert_equal next_number, owner.membership.number

    assert_equal 1, owner.fees.length
    assert owner.fees.find { |fee| fee.category == 'Prorated' }
  end

  test 'register with skip_fees' do
    owner = build_user()
    category = EffectiveMemberships.MembershipCategory.first

    refute owner.membership.present?
    assert_equal 0, owner.fees.length

    next_number = EffectiveMemberships.Registrar.next_membership_number(owner, to: category)
    assert EffectiveMemberships.Registrar.register!(owner, to: category, skip_fees: true)

    assert owner.membership.present?
    assert_equal next_number, owner.membership.number

    assert_equal 0, owner.fees.length
    assert owner.membership.fees_paid_period.present?
    assert owner.membership.fees_paid_through_period.present?
  end

  test 'reclassify' do
    owner = build_member()
    owner.fees.delete_all

    from = owner.membership.category
    to = EffectiveMemberships.MembershipCategory.where.not(id: from.id).first!

    assert EffectiveMemberships.Registrar.reclassify!(owner, to: to)

    assert_equal to, owner.membership.category

    assert_equal 2, owner.fees.length
    assert owner.fees.find { |fee| fee.category == 'Prorated' }
    assert owner.fees.find { |fee| fee.category == 'Discount' }
  end

  test 'bad standing' do
    owner = build_member()
    refute owner.membership.bad_standing?

    assert EffectiveMemberships.Registrar.bad_standing!(owner, reason: 'you know')

    assert owner.membership.bad_standing?
    assert owner.membership.bad_standing_admin?
    assert_equal 'you know', owner.membership.bad_standing_reason
  end

  test 'good standing' do
    owner = build_member()
    owner.membership.update!(bad_standing: true, bad_standing_admin: true, bad_standing_reason: 'you know')
    assert owner.membership.bad_standing?

    assert EffectiveMemberships.Registrar.good_standing!(owner)

    refute owner.membership.bad_standing?
    refute owner.membership.bad_standing_admin?
    assert owner.membership.bad_standing_reason.blank?
  end

  test 'fees paid' do
    owner = build_user()
    membership_category ||= Effective::MembershipCategory.where(title: 'Full Member').first!
    period = EffectiveMemberships.Registrar.current_period

    EffectiveMemberships.Registrar.register!(owner, to: membership_category)

    assert_equal 1, owner.outstanding_fee_payment_fees.length
    assert owner.membership.present?
    assert owner.membership.fees_paid_period.blank?
    assert owner.membership.fees_paid_through_period.blank?

    assert EffectiveMemberships.Registrar.fees_paid!(owner)

    assert_equal 0, owner.outstanding_fee_payment_fees.length
    assert_equal period, owner.membership.fees_paid_period
    assert_equal period.end_of_year, owner.membership.fees_paid_through_period
  end

  test 'remove' do
    owner = build_member()
    date = Time.zone.now + 1.year

    # Create unpurchased fees
    owner.build_renewal_fee(period: date, late_on: date, bad_standing_on: date)
    owner.save!

    # Create unpurchased order
    fp = EffectiveMemberships.FeePayment.new(owner: owner)
    fp.ready!

    # Owner is a member with outstanding fees and orders
    assert owner.membership.present?
    assert owner.outstanding_fee_payment_fees.present?
    assert owner.orders.select { |order| order.purchased? == false }.present?

    refute owner.membership_removed?
    refute owner.membership_histories.any? { |history| history.removed? }

    assert EffectiveMemberships.Registrar.remove!(owner)
    owner.reload
    owner.membership_histories.reload

    # Owner is removed and outstanding fees and orders deleted
    assert owner.membership.blank?
    assert owner.outstanding_fee_payment_fees.blank?
    assert owner.orders.select { |order| order.purchased? == false }.blank?

    # Membership history
    history = owner.membership_histories.last

    assert history.removed?
    assert history.membership_category.blank?
    assert history.number.blank?

    assert owner.membership_removed?
    assert_equal Time.zone.now.to_date, owner.membership_removed_on
  end

end
