EffectiveOrganizations.setup do |config|
  config.organizations_table_name = :organizations
  config.representatives_table_name = :representatives

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Configure the class responsible for the organization.
  config.organization_class_name = '::Organization'
end
