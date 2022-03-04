require 'effective_resources'
require 'effective_memberships/engine'
require 'effective_memberships/version'

module EffectiveMemberships

  def self.config_keys
    [
      :categories_table_name, :applicants_table_name, :applicant_reviews_table_name, :fee_payments_table_name,
      :category_class_name, :applicant_class_name, :applicant_review_class_name, :fee_payment_class_name, :registrar_class_name, :membership_card_class_name,
      :additional_fee_types, :applicant_reviews,
      :layout,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :mailer_subject, :use_effective_email_templates
    ]
  end

  include EffectiveGem

  def self.Category
    category_class_name&.constantize || Effective::Category
  end

  def self.Applicant
    applicant_class_name&.constantize || Effective::Applicant
  end

  def self.ApplicantReview
    applicant_review_class_name&.constantize || Effective::ApplicantReview
  end

  def self.FeePayment
    fee_payment_class_name&.constantize || Effective::FeePayment
  end

  def self.MembershipCard
    membership_card_class_name&.constantize || Effective::MembershipCard
  end

  def self.applicant_reviews?
    applicant_reviews == true
  end

  # Singleton
  def self.Registrar
    klass = registrar_class_name&.constantize || Effective::Registrar
    klass.new
  end

  def self.mailer_class
    mailer&.constantize || Effective::MembershipsMailer
  end

  def self.fee_types
    required = ['Applicant', 'Prorated', 'Discount', 'Renewal', 'Late', 'Admin']
    additional = Array(additional_fee_types)

    (required + additional).uniq.sort
  end

  # You can delete these if unpurchased
  def self.custom_fee_types
    ['Admin']
  end

end
