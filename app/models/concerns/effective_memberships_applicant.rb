# frozen_string_literal: true

# EffectiveMembershipsApplicant
#
# Mark your owner model with effective_memberships_applicant to get all the includes

module EffectiveMembershipsApplicant
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_applicant
      include ::EffectiveMembershipsApplicant
    end
  end

  module ClassMethods
    def effective_memberships_applicant?; true; end

    # For effective_category_applicant_wizard_steps_collection
    def required_wizard_steps
      [:start, :select, :summary, :billing, :checkout, :submitted]
    end

    def categories
      ['Apply to Join', 'Apply to Reclassify']
    end
  end

  included do
    acts_as_email_form
    acts_as_purchasable_parent
    acts_as_tokened

    acts_as_statused(
      :draft,         # Just Started
      :submitted,     # Completed wizard. Paid applicant fee.
      :missing_info,  # Admin has indicated information is missing. The applicant can edit applicant and add info
      :completed,     # Admin has received all deliverables. The application is complete and ready for review.
      :reviewed,      # All applicant reviews completed
      :declined,      # Exit state. Application was declined.
      :approved       # Exit state. Application was approved.
    )

    acts_as_wizard(
      start: 'Start',
      select: 'Select Application Type',
      demographics: 'Demographics',
      education: 'Education',
      course_amounts: 'Courses',
      experience: 'Work Experience',
      references: 'References',
      files: 'Attach Files',
      stamp: 'Professional Stamp',
      declarations: 'Declarations',
      summary: 'Review',
      billing: 'Billing Address',
      checkout: 'Checkout',
      submitted: 'Submitted'
    )

    acts_as_purchasable_wizard

    log_changes(except: :wizard_steps) if respond_to?(:log_changes)

    has_many_attached :applicant_files

    # Declarations Step
    attr_accessor :declare_code_of_ethics
    attr_accessor :declare_truth

    # Admin Approve Step
    attr_accessor :approved_membership_number
    attr_accessor :approved_membership_date

    # Application Namespace
    belongs_to :owner, polymorphic: true
    accepts_nested_attributes_for :owner

    belongs_to :category, polymorphic: true, optional: true
    belongs_to :from_category, polymorphic: true, optional: true

    has_many :applicant_reviews, -> { order(:id) }, as: :applicant, inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_reviews, reject_if: :all_blank, allow_destroy: true

    # Effective Namespace
    has_many :applicant_courses, -> { order(:id) }, class_name: 'Effective::ApplicantCourse', as: :applicant, inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_courses, reject_if: :all_blank, allow_destroy: true

    has_many :applicant_educations, -> { order(:id) }, class_name: 'Effective::ApplicantEducation', as: :applicant, inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_educations, reject_if: :all_blank, allow_destroy: true

    has_many :applicant_experiences, -> { order(:id) }, class_name: 'Effective::ApplicantExperience', as: :applicant, inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_experiences, reject_if: :all_blank, allow_destroy: true

    has_many :applicant_references, -> { order(:id) }, class_name: 'Effective::ApplicantReference', as: :applicant, inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_references, reject_if: :all_blank, allow_destroy: true

    has_many :stamps, -> { order(:id) }, class_name: 'Effective::Stamp', as: :applicant, inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :stamps, reject_if: :all_blank, allow_destroy: true

    # Effective Namespace polymorphic
    has_many :fees, -> { order(:id) }, class_name: 'Effective::Fee', as: :parent, inverse_of: :parent, dependent: :destroy
    accepts_nested_attributes_for :fees, reject_if: :all_blank, allow_destroy: true

    has_many :orders, -> { order(:id) }, class_name: 'Effective::Order', as: :parent, inverse_of: :parent, dependent: :destroy
    accepts_nested_attributes_for :orders

    effective_resource do
      applicant_type         :string

      # Acts as Statused
      status                 :string, permitted: false
      status_steps           :text, permitted: false

      # Dates
      submitted_at           :datetime
      completed_at           :datetime
      reviewed_at            :datetime
      approved_at            :datetime

      # Declined
      declined_at            :datetime
      declined_reason        :text

      # Missing Info
      missing_info_at        :datetime
      missing_info_reason    :text

      # Applicant Educations
      applicant_educations_details    :text

      # Applicant Experiences
      applicant_experiences_months    :integer
      applicant_experiences_details   :text

      # Additional Information
      additional_information          :text

      # Acts as Wizard
      wizard_steps                    :text, permitted: false

      timestamps
    end

    scope :deep, -> { includes(:owner, :category, :from_category, :orders) }
    scope :sorted, -> { order(:id) }

    scope :in_progress, -> { where.not(status: [:approved, :declined]) }
    scope :done, -> { where(status: [:approved, :declined]) }

    scope :not_draft, -> { where.not(status: :draft) }

    # Set Apply to Join or Reclassification
    before_validation(if: -> { new_record? && owner.present? }) do
      self.applicant_type ||= (owner.membership.blank? ? 'Apply to Join' : 'Apply to Reclassify')
      self.from_category ||= owner.membership&.category
    end

    before_validation(if: -> { current_step == :select && category_id.present? }) do
      self.category_type ||= EffectiveMemberships.Category.name
    end

    before_validation(if: -> { current_step == :experience }) do
      assign_applicant_experiences_months!
    end

    # All Steps validations
    validates :owner, presence: true
    validates :from_category, presence: true, if: -> { reclassification? }

    validate(if: -> { reclassification? }) do
      errors.add(:category_id, "can't reclassify to existing category") if category_id == from_category_id
    end

    # Start Step
    with_options(if: -> { current_step == :start && owner.present? }) do
      validate do
        errors.add(:base, 'may not have outstanding fees') if owner.outstanding_fee_payment_fees.present?
      end
    end

    # Select Step
    with_options(if: -> { current_step == :select || has_completed_step?(:select) }) do
      validates :applicant_type, presence: true
      validates :category, presence: true
    end

    # Applicant Educations Step
    with_options(if: -> { current_step == :education }) do
      validate do
        required = min_applicant_educations()
        existing = applicant_educations().reject(&:marked_for_destruction?).length

        self.errors.add(:applicant_educations, "please include #{required} or more educations") if existing < required
      end
    end

    # Applicant Experiences Step
    with_options(if: -> { current_step == :experience }) do
      validates :applicant_experiences_months, presence: true

      validate do
        if (min = min_applicant_experiences_months) > applicant_experiences_months.to_i
          self.errors.add(:applicant_experiences_months, "must be at least #{min} months, or #{min / 12} years")
        end
      end

      # Make sure none of the full time applicant_experience dates overlap
      validate do
        experiences = applicant_experiences.reject(&:marked_for_destruction?).select(&:full_time?)

        experiences.find do |x|
          (experiences - [x]).find do |y|
            next unless (x.start_on..x.end_on).overlaps?(y.start_on..y.end_on)
            x.errors.add(:start_on, "can't overlap when full time")
            x.errors.add(:end_on, "can't overlap when full time")
            y.errors.add(:start_on, "can't overlap when full time")
            y.errors.add(:end_on, "can't overlap when full time")
            self.errors.add(:applicant_experiences, "can't have overlaping dates for full time experiences")
          end
        end
      end
    end

    with_options(if: -> { current_step == :course_amounts }) do
      validate do
        required = min_applicant_courses()
        existing = applicant_courses().reject(&:marked_for_destruction?).length

        self.errors.add(:applicant_courses, "please include #{required} or more courses") if existing < required
      end
    end

    # Applicant References Step
    with_options(if: -> { current_step == :references }) do
      validate do
        required = min_applicant_references()
        existing = applicant_references().reject(&:marked_for_destruction?).length

        self.errors.add(:applicant_references, "please include #{required} or more references") if existing < required
      end
    end

    # Applicant Files Step
    with_options(if: -> { current_step == :files }) do
      validate do
        required = min_applicant_files()
        existing = applicant_files().length

        self.errors.add(:applicant_files, "please include #{required} or more files") if existing < required
      end
    end

    # Declarations Step
    with_options(if: -> { current_step == :declarations }) do
      validates :declare_code_of_ethics, acceptance: true
      validates :declare_truth, acceptance: true
    end

    # Admin Approve
    validate(if: -> { approved_membership_date.present? }) do
      if approved_membership_date.to_date > Time.zone.now.to_date
        errors.add(:approved_membership_date, "can't be in the future")
      elsif approved_membership_date.to_date < (Time.zone.now - 1.year).to_date
        errors.add(:approved_membership_date, "can't be more than 1 year in the past")
      end
    end

    # Admin Decline
    validates :declined_reason, presence: true, if: -> { declined? }

    # Admin Missing Info
    validates :missing_info_reason, presence: true, if: -> { missing_info? }

    # These two try completed and try reviewed
    # before_save(if: -> { submitted? }) { complete! }
    # before_save(if: -> { completed? }) { review! }

    # Clear required steps memoization
    after_save { @_required_steps = nil }

    # This required_steps is defined inside the included do .. end block so it overrides the acts_as_wizard one.
    def required_steps
      return self.class.test_required_steps if Rails.env.test? && self.class.test_required_steps.present?

      @_required_steps ||= begin
        wizard_steps = self.class.all_wizard_steps
        required_steps = self.class.required_wizard_steps

        applicant_steps = Array(category&.applicant_wizard_steps)

        # Special logic for stamp step
        applicant_steps.delete(:stamp) unless apply_to_join?

        wizard_steps.select do |step|
          required_steps.include?(step) || category.blank? || applicant_steps.include?(step)
        end
      end
    end

    def can_visit_step?(step)
      if missing_info?
        return [:start, :select, :billing, :checkout].exclude?(step)
      end

      can_revisit_completed_steps(step)
    end

    # All Fees and Orders
    def submit_fees
      # Find or build submit fee
      fee = fees.first || fees.build(owner: owner, fee_type: 'Applicant')

      unless fee.purchased?
        fee.assign_attributes(
          category: category,
          price: category.applicant_fee,
          tax_exempt: category.applicant_fee_tax_exempt,
          qb_item_name: category.applicant_fee_qb_item_name
        )
      end

      # Update stamp price
      stamp = stamps.first

      if stamp.present? && !stamp.purchased?
        stamp.assign_attributes(
          price: category.stamp_fee,
          tax_exempt: category.stamp_fee_tax_exempt,
          qb_item_name: category.stamp_fee_qb_item_name
        )
      end

      (fees + stamps)
    end

    # Draft -> Submitted requirements
    def submit!
      raise('already submitted') if was_submitted?
      raise('expected a purchased order') unless submit_order&.purchased?

      wizard_steps[:checkout] ||= Time.zone.now
      wizard_steps[:submitted] = Time.zone.now

      submitted!
      stamps.each { |stamp| stamp.submit! }

      after_commit do
        applicant_references.each { |reference| reference.notify! if reference.submitted? }
      end

      true
    end

  end

  # Instance Methods
  def to_s
    if category.present? && category.present?
      [
        owner.to_s,
        '-',
        category,
        'for',
        category,
        ("from #{from_category}" if reclassification?)
      ].compact.join(' ')
    else
      'New Applicant'
    end
  end

  def apply_to_join?
    applicant_type == 'Apply to Join'
  end

  def reclassification?
    applicant_type == 'Apply to Reclassify'
  end

  def owner_label
    owner_type.to_s.split('::').last
  end

  def in_progress?
    !approved? && !declined?
  end

  def done?
    approved? || declined?
  end

  def status_label
    (status_was || status).to_s.gsub('_', ' ')
  end

  def summary
    case status_was
    when 'draft'
      "Applicant has not yet completed the #{category} wizard steps or paid to submit this application. This application will transition to 'submitted' after payment has been collected."
    when 'submitted'
      summary = "Application has been purchased and submitted. The following tasks must be done before this application will transition to 'completed':"
      items = completed_requirements.map { |item, done| "<li>#{item}: #{done ? 'Complete' : 'Incomplete'}</li>" }.join
      "<p>#{summary}</p><ul>#{items}</ul>"
    when 'completed'
      if applicant_reviews_required?
        "All required materials have been provided. This application will transition to 'reviewed' after all reviewers have voted."
      else
        "This application has been completed and is now ready for an admin to approve or decline it. If approved, prorated fees will be generated."
      end
    when 'missing_info'
      "Missing the following information: <ul><li>#{missing_info_reason}</li></ul>"
    when 'reviewed'
      "This application has been reviewed and is now ready for an admin to approve or decline it. If approved, prorated fees will be generated."
    when 'approved'
      "The application has been approved! All done!"
    when 'declined'
      "This application has been declined."
    else
      raise("unexpected status #{status}")
    end.html_safe
  end

  # Used by the select step
  def can_apply_categories_collection
    categories = EffectiveMemberships.Category.sorted.can_apply

    if owner.blank? || owner.membership.blank?
      return categories.where(can_apply_new: true)
    end

    category_ids = owner.membership.category_ids

    categories.select do |cat|
      cat.can_apply_existing? ||
      (cat.can_apply_restricted? && (category_ids & cat.can_apply_restricted_ids).present?)
    end
  end

  def select!
    raise('cannot select a submitted applicant') if was_submitted?
    raise('cannot select a purchased applicant') if orders.any? { |order| order.purchased? }

    # Reset the progress so far. They have to click through screens again.
    assign_attributes(wizard_steps: wizard_steps.slice(:start, :select))

    save!
  end

  # Educations Step
  def min_applicant_educations
    category&.min_applicant_educations.to_i
  end

  # Courses Amounts step
  def min_applicant_courses
    category&.min_applicant_courses.to_i
  end

  def applicant_course_areas_collection
    Effective::ApplicantCourseArea.deep.sorted
  end

  def applicant_course_names_collection(applicant_course_area:)
    applicant_course_area.applicant_course_names
  end

  def applicant_course(applicant_course_name: nil)
    applicant_courses.find { |ac| ac.applicant_course_name_id == applicant_course_name.id } ||
    applicant_courses.build(applicant_course_name: applicant_course_name, applicant_course_area: applicant_course_name.applicant_course_area)
  end

  def applicant_course_area_sum(applicant_course_area:)
    applicant_courses.select { |ac| ac.applicant_course_area_id == applicant_course_area.id }.sum { |ac| ac.amount.to_i }
  end

  def applicant_courses_sum
    applicant_courses.sum { |ac| ac.amount.to_i }
  end

  # Work Experiences Step
  def min_applicant_experiences_months
    category&.min_applicant_experiences_months.to_i
  end

  # References Step
  def min_applicant_references
    category&.min_applicant_references.to_i
  end

  # Files Step
  def min_applicant_files
    category&.min_applicant_files.to_i
  end

  # Stamps step
  def stamp
    stamps.first || stamps.build(
      owner: owner,
      name: owner.to_s,
      shipping_address: (owner.try(:shipping_address) || owner.try(:billing_address)),
      price: 0
    )
  end

  # The submit! method used to be here
  # But it needs to be inside the included do block
  # So see above. Sorry.

  def applicant_references_required?
    min_applicant_references > 0
  end

  # When an application is submitted, these must be done to go to completed.
  # An Admin can override this and just set them to completed.
  def completed_requirements
    {
      'Applicant References' => (!applicant_references_required? || applicant_references.count(&:completed?) >= min_applicant_references)
    }
  end

  def complete!
    raise('applicant must have been submitted to complete!') unless was_submitted?

    # Let an admin ignore these requirements if need be
    # return false unless submitted? && completed_requirements.values.all?

    assign_attributes(missing_info_reason: nil)
    completed!

    after_commit { send_email(:applicant_completed) }
    true
  end

  def missing!
    raise('applicant must have been submitted to missing!') unless was_submitted?

    missing_info!

    after_commit { send_email(:applicant_missing_info) }
    true
  end

  def resubmit!
    raise('applicant must have been submitted and missing info to resubmit!') unless was_submitted? && was_missing_info?
    raise('already submitted') if submitted?
    raise('expected a purchased order') unless submit_order&.purchased?

    assign_attributes(skip_to_step: :submitted, submitted_at: Time.zone.now)
    submitted!
  end

  # Completed -> Reviewed requirements
  def applicant_reviews_required?
    (min_applicant_reviews > 0 || applicant_reviews.present?)
  end

  def min_applicant_reviews
    category&.min_applicant_reviews.to_i
  end

  # When an application is completed, these must be done to go to reviewed
  # An Admin can override this and just set them to reviewed.
  def reviewed_requirements
    {
      'Applicant Reviews' => (!applicant_reviews_required? || applicant_reviews.count(&:completed?) >= min_applicant_reviews)
    }
  end

  def review!
    raise('applicant must have been submitted to review!') unless was_submitted?

    # Let an admin ignore these requirements if need be
    # return false unless completed? && reviewed_requirements.values.all?
    reviewed!
  end

  # Admin approves an applicant. Registers the owner. Sends an email.
  def approve!
    raise('already approved') if was_approved?
    raise('applicant must have been submitted to approve!') unless was_submitted?

    # Complete the wizard step. Just incase this is run out of order.
    wizard_steps[:checkout] ||= Time.zone.now
    wizard_steps[:submitted] ||= Time.zone.now
    assign_attributes(missing_info_reason: nil)

    approved!

    if apply_to_join?
      EffectiveMemberships.Registrar.register!(
        owner,
        to: category,
        date: approved_membership_date.presence,       # Set by the Admin Process form, or nil
        number: approved_membership_number.presence    # Set by the Admin Process form, or nil
      )
    elsif reclassification?
      EffectiveMemberships.Registrar.reclassify!(owner, to: category)
    else
      raise('unsupported approval applicant_type')
    end

    save!

    after_commit { send_email(:applicant_approved) }
    true
  end

  # Admin approves an applicant. Registers the owner. Sends an email.
  def decline!
    raise('already declined') if was_declined?
    raise('previously approved') if was_approved?
    raise('applicant must have been submitted to decline!') unless was_submitted?

    # Complete the wizard step. Just incase this is run out of order.
    wizard_steps[:checkout] ||= Time.zone.now
    wizard_steps[:submitted] ||= Time.zone.now
    declined!

    save!

    after_commit { send_email(:applicant_declined) }
    true
  end

  private

  def assign_applicant_experiences_months!
    existing = applicant_experiences.reject(&:marked_for_destruction?)
    existing.each { |ae| ae.assign_months! }

    self.applicant_experiences_months = existing.sum { |ae| ae.months.to_i }
  end

  def send_email(email)
    EffectiveMemberships.send_email(email, self, email_form_params) unless email_form_skip?
  end

end
