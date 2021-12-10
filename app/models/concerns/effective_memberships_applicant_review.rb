# frozen_string_literal: true

# EffectiveMembershipsApplicantReview
#
# Mark your category model with effective_memberships_applicant_review to get all the includes

module EffectiveMembershipsApplicantReview
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_applicant_review
      include ::EffectiveMembershipsApplicantReview
    end
  end

  module ClassMethods
    def effective_memberships_applicant_review?; true; end

    def all_wizard_steps
      const_get(:WIZARD_STEPS).keys
    end

    # For effective_membership_category_applicant_wizard_steps_collection
    def required_wizard_steps
      [:start, :recommendation, :submitted]
    end

    def recommendations
      ['Accept', 'Reject']
    end

  end

  included do
    log_changes if respond_to?(:log_changes)

    acts_as_tokened

    acts_as_statused(
      :draft,         # Just Started
      :conflicted,    # Conflict of Interest
      :accepted,      # Accepted
      :rejected       # Rejected
    )

    acts_as_wizard(
      start: 'Start',
      conflict: 'Conflict of Interest',
      education: 'Education',
      course_amounts: 'Courses',
      experience: 'Work Experience',
      references: 'References',
      files: 'Attach Files',
      declarations: 'Declarations',
      recommendation: 'Recommendation',
      submitted: 'Submitted'
    )


    belongs_to :applicant
    belongs_to :user, polymorphic: true       # The reviewer

    effective_resource do
      submitted_at              :datetime
      recommendation            :string

      comments                  :text         # Rolling comments

      # Conflict Step
      conflict_of_interest      :boolean

      # Education Step
      education_accepted        :boolean

      # Course Amounts
      course_amounts_accepted   :boolean

      # Courses
      courses_accepted          :boolean

      # Experience Step
      experience_accepted       :boolean

      # References Step
      references_accepted       :boolean

      # References Step
      files_accepted            :boolean

      timestamps
    end

    scope :deep, -> { includes(:reviewer, applicant: :user) }

    with_options(if: -> { current_step == :conflict }) do
      validates :conflict_of_interest, inclusion: { in: [true, false] }
      validates :comments, presence: true, if: -> { conflict_of_interest? }
    end

    validates :recommendation, absence: true, if: -> { done? && conflict_of_interest? }

    after_commit(on: :create, if: -> { applicant.completed? }) { notify! }

    def to_s
      'applicant review'
    end

    def in_progress?
      draft?
    end

    def done?
      !draft?
    end

    def conflict_of_interest!
      after_commit { send_email(:applicant_review_conflict_of_interest) }

      update!(conflict_of_interest: true, recommendation: nil)
      conflicted!

      applicant.save!
    end

    def accept!
      after_commit { send_email(:applicant_review_completed) }

      assign_attributes(recommendation: 'Accept')
      accepted!

      applicant.save!
    end

    def reject!
      after_commit { send_email(:applicant_review_completed) }

      assign_attributes(recommendation: 'Reject')
      rejected!

      applicant.save!
    end

    private

    def send_email(email)
      EffectiveMemberships.send_email(email, self, email_form_params) unless email_form_skip?
    end

  end
end
