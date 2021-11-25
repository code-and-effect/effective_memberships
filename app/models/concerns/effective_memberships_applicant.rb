# EffectiveMembershipsUser
#
# Mark your user model with effective_memberships_user to get all the includes

module EffectiveMembershipsApplicant
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_applicant
      include ::EffectiveMembershipsApplicant
    end
  end

  module ClassMethods
    def effective_memberships_applicant?; true; end

    def all_wizard_steps
      const_get(:WIZARD_STEPS).keys
    end

    # For effective_membership_category_applicant_wizard_steps_collection
    def required_wizard_steps
      [:start, :select, :summary, :billing, :checkout, :submitted]
    end

  end

  included do
    acts_as_email_form
    acts_as_purchasable_parent
    acts_as_tokened

    acts_as_statused(
      :draft,       # Just Started
      :submitted,   # Completed wizard. Paid applicant fee.
      :completed,   # Admin has received all deliverables. The application is complete and ready for review.
      :reviewed,    # All applicant reviews completed
      :declined,    # Exit state. Application was declined.
      :approved     # Exit state. Application was approved.
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
      declarations: 'Declarations',
      summary: 'Review',
      billing: 'Billing',
      checkout: 'Checkout',
      submitted: 'Submitted'
    )

    log_changes(except: :wizard_steps) if respond_to?(:log_changes)

    has_many_attached :applicant_files

    # Declarations Step
    attr_accessor :declare_code_of_ethics
    attr_accessor :declare_truth

    # Admin Approve Step
    attr_accessor :approved_membership_number
    attr_accessor :approved_membership_date

    # Application Namespace
    belongs_to :user, polymorphic: true
    accepts_nested_attributes_for :user

    belongs_to :membership_category, polymorphic: true, optional: true
    belongs_to :from_membership_category, polymorphic: true, optional: true

    has_many :applicant_reviews, -> { order(:id) }, inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_reviews, reject_if: :all_blank, allow_destroy: true

    # Effective Namespace
    has_many :applicant_courses, -> { order(:id) }, class_name: 'Effective::ApplicantCourse', inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_courses, reject_if: :all_blank, allow_destroy: true

    has_many :applicant_educations, -> { order(:id) }, class_name: 'Effective::ApplicantEducation', inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_educations, reject_if: :all_blank, allow_destroy: true

    has_many :applicant_experiences, -> { order(:id) }, class_name: 'Effective::ApplicantExperience', inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_experiences, reject_if: :all_blank, allow_destroy: true

    has_many :applicant_references, -> { order(:id) }, class_name: 'Effective::ApplicantReference', inverse_of: :applicant, dependent: :destroy
    accepts_nested_attributes_for :applicant_references, reject_if: :all_blank, allow_destroy: true

    has_many :fees, -> { order(:id) }, as: :parent, class_name: 'Effective::Fee', dependent: :nullify
    accepts_nested_attributes_for :fees, reject_if: :all_blank, allow_destroy: true

    has_many :orders, -> { order(:id) }, as: :parent, class_name: 'Effective::Order', dependent: :nullify
    accepts_nested_attributes_for :orders

    effective_resource do
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

      # Applicant Educations
      applicant_educations_details  :text

      # Applicant Experiences
      applicant_experiences_months   :integer
      applicant_experiences_details  :text

      # Acts as Wizard
      wizard_steps           :text, permitted: false

      timestamps
    end

    scope :deep, -> { includes(:user, :membership_category, :from_membership_category, :orders) }
    scope :sorted, -> { order(:id) }

    scope :in_progress, -> { where.not(status: [:approved, :declined]) }
    scope :done, -> { where(status: [:approved, :declined]) }

    before_validation(if: -> { current_step == :start && user && user.membership }) do
      self.from_membership_category ||= user.membership.category
    end

    before_validation(if: -> { current_step == :select && membership_category_id.present? }) do
      self.membership_category_type ||= EffectiveMemberships.MembershipCategory.name
    end

    before_validation(if: -> { current_step == :experience }) do
      assign_applicant_experiences_months!
    end

    # All Steps validations
    validates :user, presence: true

    # Select Step
    with_options(if: -> { current_step == :select || has_completed_step?(:select) }) do
      validates :membership_category, presence: true
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

    # These two try completed and try reviewed
    before_save(if: -> { submitted? }) { complete! }
    before_save(if: -> { completed? }) { review! }

    # Clear required steps memoization
    after_save { @_required_steps = nil }

    # This required_steps is defined inside the included do .. end block so it overrides the acts_as_wizard one.
    def required_steps
      return self.class.test_required_steps if Rails.env.test? && self.class.test_required_steps.present?

      @_required_steps ||= begin
        wizard_steps = self.class.all_wizard_steps
        required_steps = self.class.required_wizard_steps

        applicant_steps = Array(membership_category&.applicant_wizard_steps)

        wizard_steps.select do |step|
          required_steps.include?(step) || membership_category.blank? || applicant_steps.include?(step)
        end
      end
    end

    after_purchase do |_order|
      raise('expected submit_order to be purchased') unless submit_order&.purchased?
      submit_purchased!
    end

  end

  # Instance Methods
  def in_progress?
    !approved? && !declined?
  end

  def done?
    approved? || declined?
  end

  def can_visit_step?(step)
    can_revisit_completed_steps(step)
  end

  def category
    'Apply to Join'
  end

  def summary
    case status
    when 'draft'
      "Applicant has not yet completed the #{category} wizard steps or paid to submit this application. This application will transition to 'submitted' after payment has been collected."
    when 'submitted'
      summary = "Application has been purchased and submitted. The following tasks must be done before this application will transition to 'completed':"
      items = completed_requirements.map { |item, done| content_tag(:li, "#{item}: #{done ? 'Complete' : 'Incomplete'}") }.join.html_safe
      content_tag(:p, summary) + content_tag(:ul, items)
    when 'completed'
      if applicant_reviews_required?
        "All required materials have been provided. This application will transition to 'reviewed' after all reviewers have voted."
      else
        "This application has been completed and is now ready for an admin to approve or decline it. If approved, prorated fees will be generated."
      end
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
  def can_apply_membership_categories_collection
    categories = EffectiveMemberships.MembershipCategory.sorted.can_apply

    if user.blank? || user.membership.blank?
      return categories.where(can_apply_new: true)
    end

    categories.select do |cat|
      cat.can_apply_existing? ||
      (cat.can_apply_restricted? && cat.can_apply_restricted_ids.include?(user.membership.category_id))
    end
  end

  def select!
    raise('cannot select a submitted applicant') if was_submitted?
    raise('cannot select a purchased applicant') if orders.any? { |order| order.purchased? }

    # Reset the progress so far. They have to click through screens again.
    assign_attributes(wizard_steps: wizard_steps.slice(:start, :select))

    # Delete any fees and orders. Keep all other data.
    submit_fees.each { |fee| fee.mark_for_destruction }
    submit_order.mark_for_destruction if submit_order

    save!
  end

  # Educations Step
  def min_applicant_educations
    membership_category&.min_applicant_educations.to_i
  end

  # Courses Amounts step
  def min_applicant_courses
    membership_category&.min_applicant_courses.to_i
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
    membership_category&.min_applicant_experiences_months.to_i
  end

  # References Step
  def min_applicant_references
    membership_category&.min_applicant_references.to_i
  end

  # Files Step
  def min_applicant_files
    membership_category&.min_applicant_files.to_i
  end

  # All Fees and Orders
  def submit_fees
    fees.select { |fee| fee.applicant_submit_fee? }
  end

  def submit_order
    orders.find { |order| order.purchasables.any?(&:applicant_submit_fee?) }
  end

  def find_or_build_submit_fees
    return submit_fees if submit_fees.present?

    fees.build(
      user: user,
      category: 'Applicant',
      membership_category: membership_category,
      price: membership_category.applicant_fee
    )

    submit_fees
  end

  def find_or_build_submit_order
    order = submit_order || orders.build(user: user)

    # Adds fees, but does not overwrite any existing price.
    submit_fees.each do |fee|
      order.add(fee) unless order.purchasables.include?(fee)
    end

    # From Billing Step
    order.billing_address = user.billing_address

    order
  end

  # Should be indempotent.
  def build_submit_fees_and_order
    return false if was_submitted?

    fees = find_or_build_submit_fees()
    raise('already has purchased submit fees') if fees.any? { |fee| fee.purchased? }

    order = find_or_build_submit_order()
    raise('already has purchased submit order') if order.purchased?

    true
  end

  # User clicks on the Billing step. Next step is Checkout
  def billing!
    ready!
  end

  # Ready to check out
  def ready!
    build_submit_fees_and_order
    save!
  end

  # Called automatically via after_purchase hook above
  def submit_purchased!
    return false if was_submitted?

    wizard_steps[:checkout] = Time.zone.now
    submit!
  end

  # Draft -> Submitted requirements
  def submit!
    raise('already submitted') if was_submitted?
    raise('expected a purchased order') unless submit_order&.purchased?

    after_commit do
      applicant_references.each { |reference| reference.notify! if reference.submitted? }
    end

    wizard_steps[:checkout] ||= Time.zone.now
    wizard_steps[:submitted] = Time.zone.now
    submitted!
  end

  # Submitted -> Completed requirements

  def applicant_references_required?
    (min_applicant_references > 0 || applicant_references.present?)
  end

  # When an application is submitted, these must be done to go to completed
  def completed_requirements
    {
      'Applicant References' => (!applicant_references_required? || applicant_references.count(&:completed?) >= min_applicant_references)
    }
  end

  def complete!
    return false unless submitted? && completed_requirements.values.all?
    # Could send registrar an email here saying this applicant is ready to review
    completed!
  end

  # Completed -> Reviewed requirements
  def applicant_reviews_required?
    (min_applicant_reviews > 0 || applicant_reviews.present?)
  end

  def min_applicant_reviews
    membership_category&.min_applicant_reviews.to_i
  end

  # When an application is completed, these must be done to go to reviewed
  def reviewed_requirements
    {
      'Applicant Reviews' => (!applicant_reviews_required? || applicant_reviews.count(&:completed?) >= min_applicant_reviews)
    }
  end

  def review!
    return false unless completed? && reviewed_requirements.values.all?
    # Could send registrar an email here saying this applicant is ready to approve
    reviewed!
  end

  # Admin approves an applicant. Registers the user. Sends an email.
  def approve!
    raise('already approved') if was_approved?
    raise('applicant must have been submitted to approve!') unless was_submitted?

    # Complete the wizard step. Just incase this is run out of order.
    wizard_steps[:checkout] ||= Time.zone.now
    wizard_steps[:submitted] ||= Time.zone.now
    approved!

    EffectiveMemberships.Registrar.register!(
      user,
      to: membership_category,
      date: approved_membership_date.presence,       # Set by the Admin Process form, or nil
      number: approved_membership_number.presence    # Set by the Admin Process form, or nil
    )

    after_commit { send_email(:applicant_approved) }

    save!
  end

  # Admin approves an applicant. Registers the user. Sends an email.
  def decline!
    raise('already declined') if was_declined?
    raise('previously approved') if was_approved?
    raise('applicant must have been submitted to decline!') unless was_submitted?

    # Complete the wizard step. Just incase this is run out of order.
    wizard_steps[:checkout] ||= Time.zone.now
    wizard_steps[:submitted] ||= Time.zone.now
    declined!

    after_commit { send_email(:applicant_declined) }

    save!
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
