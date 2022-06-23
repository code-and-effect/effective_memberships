require 'test_helper'

class ApplicantEndorsementsTest < ActiveSupport::TestCase

  test 'build_applicant_endorsement is valid' do
    build_applicant_endorsement().valid?
  end

  test 'submitting an application sends notification emails' do
    applicant_endorsement = create_applicant_endorsement!
    applicant = applicant_endorsement.applicant

    assert applicant.draft?
    assert applicant_endorsement.submitted?
    assert applicant_endorsement.last_notified_at.blank?

    applicant.ready!

    assert_email(to: applicant_endorsement.email) do
      applicant.submit_order.purchase!
    end

    applicant.reload
    applicant_endorsement.reload

    assert applicant.was_submitted?
    assert applicant_endorsement.submitted?
    assert applicant_endorsement.last_notified_at.present?
  end

end
