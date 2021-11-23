module EffectiveMembershipsHelper

  def effective_memberships_categories
    @effective_memberships_categories ||= EffectiveMemberships.MembershipCategory.deep.sorted
  end

  def edit_effective_applicants_wizard?
    params[:controller] == 'effective/applicants' && defined?(resource) && resource.draft?
  end

  def edit_effective_fee_payments_wizard?
    params[:controller] == 'effective/fee_payments' && defined?(resource) && resource.draft?
  end

end
