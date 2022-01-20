class Organization < ApplicationRecord
  acts_as_addressable :billing

  effective_organizations_organization
  effective_memberships_owner
end
