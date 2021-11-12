EffectiveMemberships.setup do |config|
  config.membership_categories_table_name = :membership_categories
  config.applicants_table_name = :applicants
  config.fees_table_name = :fees

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Membership Categories Settings
  # Configure the class responsible for the membership categories.
  # This should extend from Effective::MembershipCategory
  # And handle all the business logic for your membership categories.
  # config.membership_category = 'Effective::MembershipCategory'
  # config.applicant = 'Effective::Applicant'
  # config.fee = 'Effective::Fee'

  # Mailer Configuration
  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::MembershipsMailer'

  # Configure the parent class responsible to send e-mails.
  # config.parent_mailer = 'ActionMailer::Base'

  # Default deliver method
  # config.deliver_method = :deliver_later

  # Default layout
  config.mailer_layout = 'effective_memberships_mailer_layout'

  # Default From
  config.mailer_sender = "no-reply@example.com"

  # Send Admin correspondence To
  config.mailer_admin = "admin@example.com"

  # Will work with effective_email_templates gem:
  # - The audit and audit review email content will be preopulated based off the template
  # - Uses an EmailTemplatesMailer mailer instead of ActionMailer::Base for default parent_mailer
  config.use_effective_email_templates = false
end
