module EffectiveMembershipsTestBuilder

  def create_effective_applicant!
    build_effective_applicant.tap(&:save!)
  end

  def build_applicant(user: nil, membership_category: nil)
    membership_category ||= Effective::MembershipCategory.where(title: 'Full Member').first!
    user ||= build_user_with_address()

    #category ||= 'Apply to Join' if user.registrant_category.blank?

    applicant = Effective::Applicant.new(user: user, membership_category: membership_category)
    applicant.save!
    applicant
  end

  def build_submitted_applicant(user: nil, membership_category: nil)
    applicant = build_applicant(user: user, membership_category: membership_category)
    applicant.ready!
    applicant.submit_order.purchase!
    applicant.reload
    applicant
  end

  def create_applicant_reference!
    build_applicant_reference.tap(&:save!)
  end

  def build_applicant_reference(applicant: nil)
    applicant ||= build_applicant()

    applicant.applicant_references.build(
      name: 'Reference Name',
      email: 'reference@somewhere.com',
      phone: '(444) 444-4444',
      known: Effective::ApplicantReference::KNOWNS.sample,
      relationship: Effective::ApplicantReference::RELATIONSHIPS.sample,
    )
  end

  def build_membership_category
    Effective::MembershipCategory.new(
      title: 'Category A',
      can_apply_new: true,
      can_apply_existing: true,
      applicant_fee: 100_00,
      annual_fee: 250_00,
      prorated_jan: 120, prorated_feb: 110, prorated_mar: 100, prorated_apr: 90, prorated_may: 80, prorated_jun: 70,
      prorated_jul: 60, prorated_aug: 50, prorated_sep: 40, prorated_oct: 30, prorated_nov: 20, prorated_dec: 10
    )
  end

  def create_user!
    build_user.tap { |user| user.save! }
  end

  def build_user
    @user_index ||= 0
    @user_index += 1

    User.new(
      email: "user#{@user_index}@example.com",
      password: 'rubicon2020',
      password_confirmation: 'rubicon2020',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  def build_user_with_address
    user = build_user()

    user.addresses.build(
      addressable: user,
      category: 'billing',
      full_name: 'Test User',
      address1: '1234 Fake Street',
      city: 'Victoria',
      state_code: 'BC',
      country_code: 'CA',
      postal_code: 'H0H0H0'
    )

    user.save!
    user
  end

end
