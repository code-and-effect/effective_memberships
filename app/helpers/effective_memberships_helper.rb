module EffectiveMembershipsHelper

  def effective_memberships_status_collection
    EffectiveMemberships.Applicant::STATUSES.map do |status|
      next if status == :reviewed && !EffectiveMemberships.applicant_reviews?

      [status.to_s.gsub('_', ' '), status]
    end.compact
  end

  def effective_memberships_select_applicant_organization_collection(resource)
    user = (resource.respond_to?(:user) ? resource.user : resource)
    raise('expected an effective memberships user') unless user.class.try(:effective_memberships_user?)

    representatives = user.representatives.select { |rep| rep.is?(:owner) || rep.is?(:billing) }
    organizations = representatives.map { |rep| [rep.organization.to_s, rep.organization.id] }

    organizations + [['New Organization...', 'new']]
  end

  # This is the select yourself or organization field on FeePayments#start
  def effective_memberships_select_fee_payment_organization(resource)
    user = (resource.respond_to?(:user) ? resource.user : resource)
    raise('expected an effective memberships user') unless user.class.try(:effective_memberships_user?)

    owners = user.memberships_owners.select { |owner| owner.outstanding_fee_payment_fees.present? }

    owners.map do |owner|
      [
        owner.to_s,
        (owner.to_param if owner.kind_of?(EffectiveMemberships.Organization)) # Nil when user
      ]
    end
  end

end
