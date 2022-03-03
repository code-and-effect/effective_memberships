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
  # config.additional_fee_types = []

  # Applicant Reviews
  # When true, display the reviewed state and require Category.min_applicant_reviews
  # When false, hide the reviewed state entirely
  # config.applicant_reviews = false

  # Mailer Settings
  # Please see config/initializers/effective_resources.rb for default effective_* gem mailer settings
  #
  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::MembershipsMailer'
  #
  # Override effective_resource mailer defaults
  #
  # config.parent_mailer = nil      # The parent class responsible for sending emails
  # config.deliver_method = nil     # The deliver method, deliver_later or deliver_now
  # config.mailer_layout = nil      # Default mailer layout
  # config.mailer_sender = nil      # Default From value
  # config.mailer_admin = nil       # Default To value for Admin correspondence

  # Will work with effective_email_templates gem
  config.use_effective_email_templates = true
end
