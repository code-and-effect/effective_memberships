module Effective
  class Applicant < ActiveRecord::Base
    self.table_name = EffectiveMemberships.applicants_table_name.to_s

    effective_memberships_applicant
  end
end
