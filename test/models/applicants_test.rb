require 'test_helper'

class ApplicantsTest < ActiveSupport::TestCase

  test 'build_applicant is valid' do
    applicant = build_applicant()
    assert applicant.valid?
    assert_equal 'Full Member', applicant.membership_category.to_s
  end

  test 'build_submitted_applicant is valid' do
    applicant = build_submitted_applicant

    assert applicant.valid?
    assert_equal 1, applicant.submit_fees.length
    assert_equal 1, applicant.submit_order.order_items.length
    assert applicant.submit_order.purchased?

    assert applicant.submit_fees.first.purchased?
    assert applicant.user.fees.all?(&:purchased?)

    # Submitted
    assert applicant.has_completed_step?(:checkout)
    assert applicant.has_completed_step?(:submitted)
    assert applicant.submitted?
  end

  test 'required_steps are based on membership category' do
    applicant = build_applicant()
    all_steps = applicant.class::WIZARD_STEPS.keys

    # Default has all steps
    assert_equal all_steps, applicant.required_steps

    # When membership category only wants demographics
    applicant.membership_category.update!(applicant_wizard_steps: [:demographics])
    applicant.save!
    assert_equal [:start, :select, :demographics, :ready, :checkout, :submitted], applicant.required_steps

    # When no membership category
    applicant.update!(membership_category: nil)
    assert_equal all_steps, applicant.required_steps
  end

  test 'moves to completed when complete' do
    applicant = build_reviewable_applicant()

    assert_equal 2, applicant.applicant_references.length

    assert applicant.completed_requirements.key?('Applicant References')
    refute applicant.completed_requirements['Applicant References']
    assert applicant.submitted?

    # Complete References
    applicant.applicant_references.each do |applicant_reference|
      applicant_reference.assign_attributes(
        reservations: false,
        work_history: 'yes',
        accept_declaration: true
      )

      applicant_reference.addresses.build(
        addressable: applicant_reference,
        category: 'reference',
        full_name: 'Test User',
        address1: '1234 Fake Street',
        city: 'Victoria',
        state_code: 'BC',
        country_code: 'CA',
        postal_code: 'H0H0H0'
      )

      applicant_reference.complete!
    end

    assert applicant.completed_requirements['Applicant References']
    assert applicant.completed?
  end

  test 'moves to reviewed when reviewed' do
    # TODO
  end

  test 'declining an applicant sends an email' do
    applicant = build_submitted_applicant()
    applicant.declined_reason = 'Test declined'

    assert_email { applicant.decline! }

    assert_equal 'declined', applicant.status
    assert applicant.declined?
  end

  test 'can decline with custom email content' do
    applicant = build_submitted_applicant()
    applicant.declined_reason = 'Test declined'

    applicant.assign_attributes(
      email_form_action: :applicant_declined,
      email_form_skip: false,
      email_form_from: 'a@b.com',
      email_form_subject: 'Test Declined Subject',
      email_form_body: 'Test Declined Body'
    )

    assert_email(body: 'Test Declined Body', subject: 'Test Declined Subject') { applicant.decline! }

    assert_equal 'declined', applicant.status
    assert applicant.declined?
  end

  test 'approving an applicant sends an email' do
    applicant = build_submitted_applicant()

    assert_email { applicant.approve! }

    assert_equal 'approved', applicant.status
    assert applicant.approved?
  end

  test 'can approve with custom email content' do
    applicant = build_submitted_applicant()

    applicant.assign_attributes(
      email_form_action: :applicant_approved,
      email_form_skip: false,
      email_form_from: 'a@b.com',
      email_form_subject: 'Test Approved Subject',
      email_form_body: 'Test Approved Body'
    )

    assert_email(body: 'Test Approved Body', subject: 'Test Approved Subject') { applicant.approve! }

    assert_equal 'approved', applicant.status
    assert applicant.approved?
  end

end
