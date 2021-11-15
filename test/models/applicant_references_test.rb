require 'test_helper'

class ApplicantReferencesTest < ActiveSupport::TestCase

  test 'build_applicant_reference is valid' do
    build_applicant_reference().valid?
  end

  test 'submitting an application sends notification emails' do
    applicant_reference = create_applicant_reference!
    applicant = applicant_reference.applicant

    assert applicant.draft?
    assert applicant_reference.submitted?
    assert applicant_reference.last_notified_at.blank?

    applicant.ready!

    assert_email(to: applicant_reference.email) do
      applicant.submit_order.purchase!
    end

    applicant.reload
    applicant_reference.reload

    assert applicant.was_submitted?
    assert applicant_reference.submitted?
    assert applicant_reference.last_notified_at.present?
  end

end
