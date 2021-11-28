require 'test_helper'

class ApplicantsReclassifyTest < ActiveSupport::TestCase

  test 'build_applicant for reclassification is valid' do
    user = build_member()

    from = user.membership.category
    to = EffectiveMemberships.MembershipCategory.where.not(id: from.id).first!

    applicant = build_applicant(user: user, membership_category: to)
    assert applicant.valid?

    assert applicant.reclassification?
    assert_equal to, applicant.membership_category
    assert_equal from, applicant.from_membership_category
  end

  test 'approving creates prorated and discount fees' do
    user = build_member()
    user.fees.delete_all

    from = user.membership.category
    to = EffectiveMemberships.MembershipCategory.where.not(id: from.id).first!

    applicant = build_submitted_applicant(user: user, membership_category: to)
    applicant.approve!

    assert_equal 3, applicant.user.fees.length

    applicant_fee = applicant.user.fees.find { |fee| fee.category == 'Applicant' }
    assert_equal applicant_fee.price, applicant.membership_category.applicant_fee

    prorated_fee = applicant.user.fees.find { |fee| fee.category == 'Prorated' }
    assert_equal prorated_fee.membership_category, applicant.membership_category
    assert_equal prorated_fee.price, applicant.membership_category.send("prorated_#{Time.zone.now.strftime('%b').downcase}").to_i

    discount_fee = applicant.user.fees.find { |fee| fee.category == 'Discount' }
    assert_equal discount_fee.membership_category, applicant.membership_category
    assert_equal discount_fee.price, 0-applicant.from_membership_category.send("prorated_#{Time.zone.now.strftime('%b').downcase}").to_i
  end

end
