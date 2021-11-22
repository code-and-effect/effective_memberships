module Effective
  class ApplicantReview < ActiveRecord::Base
    self.table_name = EffectiveMemberships.applicant_reviews_table_name.to_s

    effective_memberships_applicant_review
  end
end
