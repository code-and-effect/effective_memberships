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

end
