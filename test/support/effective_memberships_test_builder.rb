module EffectiveMembershipsTestBuilder

  def build_member(category: nil, type: :user)
    category ||= Effective::Category.where(title: 'Full Member').first!

    owner = build_user_with_address() if type == :user
    owner = build_organization_with_address() if type == :organization

    EffectiveMemberships.Registrar.register!(owner, to: category)

    fp = EffectiveMemberships.FeePayment.new(owner: owner)
    fp.ready!
    fp.submit_order.purchase!
    owner.reload

    owner
  end

  def create_effective_applicant!
    build_effective_applicant.tap(&:save!)
  end

  def build_applicant(owner: nil, category: nil, applicant_type: nil)
    category ||= Effective::Category.where(title: 'Full Member').first!
    owner ||= build_user_with_address()

    applicant_type ||= 'Apply to Join' if owner.membership.blank?
    applicant_type ||= 'Apply to Reclassify' if owner.membership.present?

    applicant = Effective::Applicant.new(owner: owner, category: category)
    applicant.save!
    applicant
  end

  def build_submitted_applicant(owner: nil, category: nil)
    applicant = build_applicant(owner: owner, category: category)
    applicant.ready!
    applicant.submit_order.purchase!
    applicant.reload
    applicant
  end

  # Note, I'm skipping over review! and just setting reviewed!
  # Because I don't wanna do all the completed requirements
  # Use build_reviewable_applicant() if you want to test the applicant reviews on a reviewable submitted applicant
  def build_reviewed_applicant(owner: nil, category: nil)
    applicant = build_submitted_applicant(owner: owner, category: category)
    applicant.reviewed!
    applicant
  end

  def build_declined_applicant(owner: nil, category: nil)
    applicant = build_reviewed_applicant(owner: owner, category: category)
    applicant.declined_reason = 'Declined'
    applicant.decline!
    applicant
  end

  def build_approved_applicant(owner: nil, category: nil)
    applicant = build_reviewed_applicant(owner: owner, category: category)
    applicant.approve!
    applicant
  end

  def build_reviewable_applicant(owner: nil, category: nil)
    applicant = build_submitted_applicant(owner: owner, category: category)

    # Build References
    applicant.min_applicant_references.times do |x|
      applicant.applicant_references.build(
        name: "Reference Name #{x}",
        email: "reference#{x}@somewhere.com",
        phone: '(444) 444-4444',
        known: Effective::ApplicantReference::KNOWNS.sample,
        relationship: Effective::ApplicantReference::RELATIONSHIPS.sample,
      )
    end

    applicant.status_steps[:references] = Time.zone.now

    # Attach Files
    file = Rails.root.join('db', 'seeds.rb')
    applicant.applicant_files.attach(io: File.open(file), filename: 'seeds.rb')

    applicant.status_steps[:files] = Time.zone.now

    applicant.save!
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

  def build_applicant_review(applicant: nil, owner: nil)
    applicant ||= build_applicant()
    reviewer ||= build_user()

    applicant.applicant_reviews.build(reviewer: reviewer)
  end

  def build_category
    Effective::Category.new(
      title: 'Category A',
      can_apply_new: true,
      can_apply_existing: true,
      create_renewal_fees: true,
      create_late_fees: true,
      applicant_fee: 100_00,
      renewal_fee: 250_00,
      late_fee: 25_00,
      prorated_jan: 120_00, prorated_feb: 110_00, prorated_mar: 100_00, prorated_apr: 90_00, prorated_may: 80_00, prorated_jun: 70_00,
      prorated_jul: 60_00, prorated_aug: 50_00, prorated_sep: 40_00, prorated_oct: 30_00, prorated_nov: 20_00, prorated_dec: 10_00
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

  def build_organization
    Organization.new(title: 'Test Organization', email: 'admin@organization.com')
  end

  def build_organization_with_address
    organization = build_organization()

    organization.addresses.build(
      addressable: organization,
      category: 'billing',
      full_name: 'Test Organization',
      address1: '1234 Fake Street',
      city: 'Victoria',
      state_code: 'BC',
      country_code: 'CA',
      postal_code: 'H0H0H0'
    )

    organization.save!
    organization
  end

end
