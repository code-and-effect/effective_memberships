class Organization < ApplicationRecord
  acts_as_addressable :billing
  effective_memberships_organization
end
