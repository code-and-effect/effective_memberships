# It's expected the app will use a class like this

module Effective
  class MembershipCategory < ActiveRecord::Base
    self.table_name = EffectiveMemberships.membership_categories_table_name.to_s

    effective_memberships_category
  end
end
