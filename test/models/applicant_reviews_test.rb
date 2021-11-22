require 'test_helper'

class ApplicantsReviewsTest < ActiveSupport::TestCase

  test 'build_applicant is valid' do
    applicant_review = build_applicant_review()
    assert applicant_review.valid?
  end

end
