module EffectiveMembershipsHelper

  def effective_memberships_categories
    @effective_memberships_categories ||= Effective::MembershipCategory.deep.sorted
  end

end
