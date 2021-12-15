module Effective
  class Category < ActiveRecord::Base
    self.table_name = EffectiveMemberships.categories_table_name.to_s

    effective_memberships_category
  end
end
