module Effective
  class Fee < ActiveRecord::Base
    self.table_name = EffectiveMemberships.fees_table_name.to_s

    effective_memberships_fee
  end
end
