module EffectiveMembershipsHelper

  def effective_memberships_categories
    @effective_memberships_categories ||= EffectiveMemberships.membership_category_class.deep.sorted
  end

end
