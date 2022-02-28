module EffectiveMembershipsHelper

  def effective_memberships_status_collection
    EffectiveMemberships.Applicant::STATUSES.map do |status|
      next if status == :reviewed && !EffectiveMemberships.applicant_reviews?

      [status.to_s.gsub('_', ' '), status]
    end.compact
  end

end
