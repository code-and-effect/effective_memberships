require 'test_helper'

class ApplicantsReclassifyTest < ActiveSupport::TestCase

  test 'build_applicant for reclassification is valid' do
    owner = build_member()

    from = owner.membership.category
    to = EffectiveMemberships.Category.where.not(id: from.id).first!

    applicant = build_applicant(owner: owner, category: to)
    assert applicant.valid?

    assert applicant.reclassification?
    assert_equal to, applicant.category
    assert_equal from, applicant.from_category
  end

  test 'approving creates prorated and discount fees' do
    owner = build_member()
    owner.fees.delete_all

    from = owner.membership.category
    to = EffectiveMemberships.Category.where.not(id: from.id).first!

    applicant = build_submitted_applicant(owner: owner, category: to)
    EffectiveResources.transaction { applicant.approve! }

    assert_equal 3, applicant.owner.fees.length

    applicant_fee = applicant.owner.fees.find { |fee| fee.fee_type == 'Applicant' }
    assert_equal applicant_fee.price, applicant.category.applicant_fee

    prorated_fee = applicant.owner.fees.find { |fee| fee.fee_type == 'Prorated' }
    assert_equal prorated_fee.category, applicant.category
    assert_equal prorated_fee.price, applicant.category.send("prorated_#{Time.zone.now.strftime('%b').downcase}").to_i

    discount_fee = applicant.owner.fees.find { |fee| fee.fee_type == 'Discount' }
    assert_equal discount_fee.category, applicant.category
    assert_equal discount_fee.price, 0-applicant.from_category.send("prorated_#{Time.zone.now.strftime('%b').downcase}").to_i
  end

end
