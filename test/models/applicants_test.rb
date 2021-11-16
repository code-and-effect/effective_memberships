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
    assert applicant.was_submitted?
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

  # test 'build_reviewed_applicant is valid' do
  #   applicant = build_reviewed_applicant

  #   assert applicant.valid?
  #   assert applicant.reviewed?
  #   assert applicant.was_submitted?
  # end

  # test 'build_declined_applicant is valid' do
  #   applicant = build_declined_applicant

  #   assert applicant.valid?
  #   assert applicant.declined?
  #   assert applicant.was_reviewed?
  # end

  # test 'build_deferred_applicant is valid' do
  #   applicant = build_deferred_applicant

  #   assert applicant.valid?
  #   assert applicant.deferred?
  #   assert applicant.was_reviewed?
  # end

  # test 'build_approved_applicant is valid' do
  #   applicant = build_approved_applicant

  #   assert applicant.valid?
  #   assert applicant.approved?
  #   assert applicant.was_reviewed?

  #   if applicant.training_required?
  #     assert applicant.train_order.present?
  #     refute applicant.train_order.purchased?

  #     assert_equal 1, applicant.train_fees.length
  #     assert_equal 1, applicant.train_order.order_items.length
  #     assert applicant.train_fees.first.kind_of?(Fees::ExamFee)
  #   end
  # end

  # test 'build_training_applicant is valid' do
  #   # We only test it once in this test suite. This no longer works. SSL error.
  #   applicant = build_training_applicant(test_udutu: true)

  #   assert applicant.valid?

  #   assert applicant.approved?
  #   assert applicant.training?  # Maybe we will use this. Maybe not.
  #   assert applicant.was_approved?
  #   assert applicant.has_completed_step?(:train_checkout)

  #   refute applicant.trained?
  #   refute applicant.has_completed_step?(:train)

  #   assert applicant.train_order.purchased?
  #   assert applicant.has_completed_step?(:train_checkout)

  #   # This doubles as a udutu integration test
  #   assert applicant.ethics_exam.present?
  #   assert applicant.user.udutu_id.present?
  #   assert applicant.user.udutu_password.present?
  #   assert_equal applicant.ethics_exam.username, applicant.user.email

  #   refute applicant.user.ethics_exam_completed?
  #   refute applicant.user.ethics_exam_completed_on.present?

  #   refute applicant.finish_order.present?
  # end

  # test 'build_trained_applicant is valid' do
  #   applicant = build_trained_applicant

  #   assert applicant.valid?
  #   assert applicant.trained?
  #   assert applicant.was_approved?
  #   assert applicant.has_completed_step?(:train_checkout)
  #   assert applicant.has_completed_step?(:training)

  #   assert applicant.ethics_exam.passed?
  #   assert applicant.user.ethics_exam_completed?
  #   assert applicant.user.ethics_exam_completed_on.present?

  #   assert applicant.finish_order.present?
  #   refute applicant.finish_order.purchased?

  #   assert_equal 2, applicant.finish_fees.length
  #   assert_equal 2, applicant.finish_order.order_items.length
  #   assert applicant.finish_fees.find { |fee| fee.kind_of?(Fees::ProratedFee) }.present?
  #   assert applicant.finish_fees.find { |fee| fee.kind_of?(Fees::SealFee) }.present?
  # end

  # test 'build_finished_applicant is valid' do
  #   applicant = build_finished_applicant

  #   assert applicant.valid?
  #   assert applicant.finished?
  #   assert applicant.was_trained?

  #   assert applicant.finish_order.purchased?
  #   assert applicant.has_completed_step?(:finish_checkout)

  #   refute applicant.has_completed_step?(:finished)
  #   refute applicant.has_completed_step?(:registered)
  # end

  # test 'build_registered_applicant is valid' do
  #   applicant = build_registered_applicant

  #   assert applicant.valid?
  #   assert applicant.registered?
  #   assert applicant.has_completed_step?(:finished)
  #   assert applicant.has_completed_step?(:registered)
  #   assert applicant.was_finished?

  #   registrant_number = (Register.main - 1).to_s
  #   assert_equal applicant.registrant_number, registrant_number
  #   assert_equal applicant.user.number, registrant_number
  #   assert_equal applicant.user.registrant_category, applicant.registrant_category
  # end

  # test 'changing an applicant category updates its fees correctly' do
  #   applicant = build_applicant(registrant_category: rpbio)

  #   # First time
  #   assert applicant.create_submit_fees_and_order!
  #   assert_equal rpbio, applicant.submit_fees.first.registrant_category
  #   assert_equal rpbio.applicant, applicant.submit_fees.first.price

  #   # So now "go back to the select step" and change the registrant category.
  #   # Now update the registrant category. The fee and order should change.
  #   applicant.update!(registrant_category: student)
  #   applicant.create_submit_fees_and_order!

  #   assert_equal student, applicant.submit_fees.first.registrant_category
  #   assert_equal student.applicant, applicant.submit_fees.first.price

  #   assert_equal student.applicant, applicant.submit_order.subtotal
  # end

  # test 'calling create_fees methods returns false once done' do
  #   applicant = build_registered_applicant()

  #   assert_equal false, applicant.create_submit_fees_and_order!
  #   assert_equal false, applicant.create_train_fees_and_order!
  #   assert_equal false, applicant.create_finish_fees_and_order!
  # end

  # test 'declining an applicant sends an email' do
  #   applicant = build_applicant()

  #   applicant.declined_reason = 'Test declined'
  #   applicant.decline!
  #   #assert_email(:applicant_declined)

  #   assert_equal 'declined', applicant.status
  #   assert applicant.declined?
  # end

  # test 'can decline with custom email content' do
  #   applicant = build_applicant()

  #   applicant.declined_reason = 'Test declined'
  #   #applicant.build_email_review(body: "ASDF ASDF", template_name: :applicant_declined)
  #   assert applicant.decline!
  #   #assert_email(:applicant_declined, body: 'ASDF ASDF')
  # end

  # test 'defering an applicant sends an email' do
  #   applicant = build_applicant()

  #   applicant.deferred_reason = 'Test deferred'
  #   assert applicant.defer!
  #   #assert_email(:applicant_deferred)

  #   assert_equal 'deferred', applicant.status
  #   assert applicant.deferred?
  # end

  # test 'can defer with custom email content' do
  #   applicant = build_applicant()

  #   applicant.deferred_reason = 'Test deferred'
  #   #applicant.build_email_review(body: "ASDF ASDF", template_name: :applicant_deferred)
  #   assert applicant.defer!
  #   #assert_email(:applicant_deferred, body: 'ASDF ASDF')
  # end

  # test 'submitting an applicant with IOD sends an email' do
  #   user = build_user_with_address()
  #   user.update!(iod: true, iod_on: Time.zone.now, iod_district: 'District', iod_details: 'Details')

  #   applicant = build_submitted_applicant(user: user)
  #   assert applicant.submitted?
  #   assert_email(:applicant_with_iod)
  # end

  # test 'approving transcripts works (no email)' do
  #   applicant = build_applicant()

  #   applicant.update!(transcripts_received: true, transcripts_received_on: Time.zone.now)
  #   assert applicant.transcripts_approve!
  #   assert applicant.transcripts_approved?
  # end

  # test 'problematic transcripts sends an email' do
  #   applicant = build_applicant()

  #   applicant.update!(transcripts_received: true, transcripts_received_on: Time.zone.now)
  #   applicant.build_email_review(body: "ASDF ASDF")

  #   applicant.transcripts_note = 'Required for problematic'
  #   assert applicant.transcripts_problematic!

  #   assert applicant.transcripts_problematic?
  #   assert_email(:applicant_transcripts_problematic)
  # end

  # test 'moves to completed when complete' do
  #   applicant = build_reviewable_applicant()

  #   assert_equal 3, applicant.applicant_references.length
  #   assert_equal 1, applicant.applicant_reports.length
  #   assert applicant.transcripts_required?

  #   refute applicant.completed_materials[:transcripts]
  #   refute applicant.completed_materials[:applicant_reports]
  #   refute applicant.completed_materials[:applicant_references]
  #   assert applicant.submitted?

  #   # Approve Transcripts
  #   applicant.update!(transcripts_status: 'Approved')

  #   assert applicant.completed_materials[:transcripts]
  #   assert applicant.submitted?

  #   # Complete Report
  #   applicant.applicant_reports.each do |applicant_report|
  #     applicant_report.assign_attributes(comments: 'Approved', accept_declaration: true)
  #     applicant_report.complete!
  #   end

  #   assert applicant.completed_materials[:applicant_reports]
  #   assert applicant.submitted?

  #   # Complete References
  #   applicant.applicant_references.each do |applicant_reference|
  #     applicant_reference.assign_attributes(
  #       reservations: false,
  #       known: 'yes',
  #       relationship: 'yes',
  #       work_history: 'yes',
  #       accept_declaration: true,
  #       experience_concepts: 'yes',
  #       experience_laws: 'yes',
  #       experience_standards: 'yes',
  #       experience_project: 'yes',
  #       experience_records: 'yes',
  #       experience_accountability: 'yes',
  #       experience_communication: 'yes',
  #     )

  #     applicant_reference.addresses.build(
  #       addressable: applicant_reference,
  #       category: 'reference',
  #       full_name: 'Test User',
  #       address1: '1234 Fake Street',
  #       city: 'Victoria',
  #       state_code: 'BC',
  #       country_code: 'CA',
  #       postal_code: 'H0H0H0'
  #     )

  #     applicant_reference.complete!
  #   end

  #   assert applicant.completed_materials[:applicant_references]

  #   assert applicant.completed?
  # end

  # test 'moves to reviewed when reviewed' do
  #   applicant = build_applicant()
  #   applicant.completed!

  #   assert_equal 1, applicant.required_applicant_review_count

  #   applicant.required_applicant_review_count.times do |x|
  #     review = applicant.applicant_reviews.build(reviewer: admin)
  #     review.build_email_review(template_name: :new_applicant_review)
  #     review.save!
  #   end

  #   assert applicant.completed?

  #   applicant.applicant_reviews.each do |applicant_review|
  #     applicant_review.accept!
  #   end

  #   assert applicant.reviewed?
  # end

  # test 'approved moves to approved' do
  #   applicant = build_submitted_applicant()
  #   applicant.approve!

  #   assert applicant.approved?
  #   refute applicant.trained?

  #   assert applicant.training_required?
  #   assert applicant.train_order.present?
  # end

  # test 'approved with an ethics_completed_on skips training' do
  #   applicant = build_submitted_applicant()
  #   applicant.user.update!(ethics_exam_completed_on: Time.zone.now, ethics_exam_completed: true)
  #   applicant.approve!

  #   assert applicant.was_approved?
  #   assert applicant.was_trained?
  #   assert applicant.trained?

  #   refute applicant.training_required?
  #   refute applicant.train_order.present?
  # end

end
