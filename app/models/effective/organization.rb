module Effective
  class Organization < ActiveRecord::Base
    self.table_name = EffectiveMemberships.organizations_table_name.to_s

    effective_memberships_organization

  end
end
