EffectiveMemberships.setup do |config|
  config.categories_table_name = :categories
  config.applicants_table_name = :applicants
  config.applicant_reviews_table_name = :applicant_reviews
  config.fee_payments_table_name = :fee_payments

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Membership Categories Settings
  # Configure the class responsible for the membership categories.
  # This should extend from Effective::Category
  # And handle all the business logic for your membership categories.
  # config.category_class_name = 'Effective::Category'
  # config.applicant_class_name = 'Effective::Applicant'
  # config.applicant_review_class_name = 'Effective::ApplicantReview'
  # config.registrar_class_name = 'Effective::Registrar'

  # Fee Categories
  # The defaults include: Applicant, Prorated, Renewal, Late, Admin
  # config.additional_fee_categories = []

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
