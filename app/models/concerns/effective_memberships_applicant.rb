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
  end

  included do
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
      experience: 'Work Experience',
      references: 'References',
      declarations: 'Declarations',
      review: 'Review',
      checkout: 'Checkout',
      submitted: 'Submitted'
    )

    log_changes(except: :wizard_steps) if respond_to?(:log_changes)

    belongs_to :user, polymorphic: true
    accepts_nested_attributes_for :user

    belongs_to :membership_category, polymorphic: true, optional: true
    belongs_to :from_membership_category, polymorphic: true, optional: true

    has_many :orders, as: :parent, class_name: 'Effective::Order', dependent: :nullify
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

      declined_at            :datetime
      declined_reason        :text

      # Acts as Wizard
      wizard_steps           :text, permitted: false

      timestamps
    end

    scope :deep, -> { includes(:user, :membership_category, :from_membership_category, :orders) }
    scope :sorted, -> { order(:id) }

    scope :in_progress, -> { where.not(status: [:approved, :declined]) }
    scope :done, -> { where(status: [:approved, :declined]) }

    validates :user, presence: true
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

end
