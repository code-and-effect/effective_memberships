module Effective
  class ApplicantReference < ActiveRecord::Base
    acts_as_tokened
    acts_as_addressable :reference
    acts_as_statused :submitted, :completed
    log_changes(to: :applicant) if respond_to?(:log_changes)

    belongs_to :applicant

    KNOWNS = ['6 months - 1 year', '1 year - 2 years', '2 - 5 years', '5 - 10 years', 'More than 10 years']
    RELATIONSHIPS = ['Supervisor', 'Employer', 'Colleague', 'Other']

    effective_resource do
      # These two fields are submitted on the Applicant wizard step
      name    :string
      email   :string
      phone   :string

      # As per acts_as_statused. For tracking the state machine.
      status            :string
      status_steps      :text

      # Reference Declaration
      known                   :string
      relationship            :string

      reservations            :boolean
      reservations_reason     :text

      work_history            :text

      accept_declaration      :boolean

      # Tracking the submission
      token                     :string
      last_notified_at          :datetime

      timestamps
    end

    # This is for the applicant wizard reports step
    def self.permitted_params
      [:id, :_destroy, :applicant_id, :name, :email, :phone]
    end

    # For the complete step
    def self.reference_params
      [
        :reference_id, :name, :email, :phone,
        :known, :relationship, :reservations, :reservations_reason, :work_history, :accept_declaration,
        reference_address: EffectiveAddresses.permitted_params
      ]
    end

    # All step validations
    validates :applicant, presence: true

    validates :name, presence: true
    validates :email, presence: true, email: true
    validates :phone, presence: true

    validates :relationship, presence: true
    validates :known, presence: true

    # When being submit by the reference
    with_options(if: -> { completed? }) do
      validates :reference_address, presence: true
      validates :reservations_reason, presence: true, if: -> { completed? && reservations? }
      validates :work_history, presence: true
      validates :accept_declaration, acceptance: true
    end

    after_commit(on: :create, if: -> { applicant.submitted? }) { notify! }

    def to_s
      name.presence || 'reference'
    end

    def notify!
      raise('expected reference email') unless email.present?

      after_commit do
        EffectiveMemberships.send_email(:applicant_reference_notification, self)
      end

      update!(last_notified_at: Time.zone.now)
    end

    def complete!
      completed!
      applicant.save!
    end
  end

end
