module EffectiveMembershipsHelper

  def effective_memberships_status_collection
    EffectiveMemberships.Applicant::STATUSES.map do |status|
      next if status == :reviewed && !EffectiveMemberships.applicant_reviews?

      [status.to_s.gsub('_', ' '), status]
    end.compact
  end

  def effective_memberships_select_organization_collection(resource)
    user = (resource.respond_to?(:user) ? resource.user : resource)
    raise('expected an effective memberships user') unless user.class.try(:effective_memberships_user?)

    representatives = user.representatives.select { |rep| rep.is?(:owner) || rep.is?(:billing) }
    organizations = representatives.map { |rep| [rep.organization.to_s, rep.organization.id] }

    organizations + [['New Organization...', 'new']]
  end

end
