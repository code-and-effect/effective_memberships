# An ApplicantEndorsement is similar to a reference, except it must be an existing member

module Effective
  class ApplicantEndorsement < ActiveRecord::Base
    acts_as_tokened

    acts_as_statused(
      :submitted, # Was submitted by the applicant
      :completed # Was completed by the endorser.
    )

    log_changes(to: :applicant) if respond_to?(:log_changes)

    belongs_to :applicant, polymorphic: true
    belongs_to :endorser, polymorphic: true, optional: true

    effective_resource do
      # These fields are submitted by the applicant
      # They should try to select an endorser from the dropdown
      # But we also allow a fallback
      unknown_member   :boolean
      endorser_email   :string
      name             :string
      phone            :string

      # As per acts_as_statused. For tracking the state machine.
      status            :string
      status_steps      :text

      # Endorser Declaration
      notes                   :text
      accept_declaration      :boolean

      # Tracking the submission
      token                     :string
      last_notified_at          :datetime

      timestamps
    end

    scope :deep, -> { all }

    # All step validations
    validates :applicant, presence: true
    validates :endorser, presence: true, unless: -> { unknown_member? }

    with_options(if: -> { unknown_member? }) do
      validates :endorser_email, presence: true, email: true
      validates :name, presence: true
      validates :phone, presence: true
    end

    # When being submit by the reference
    with_options(if: -> { completed? }) do
      validates :accept_declaration, acceptance: true
    end

    after_commit(on: :create, if: -> { applicant.was_submitted? }) { notify! }

    def self.endorser_collection(applicant)
      raise('expected an effective memberships applicant') unless applicant.class.try(:effective_memberships_applicant?)

      collection_method = EffectiveMemberships.applicant_endorsements_endorser_collection()

      if collection_method.blank?
        return (applicant.owner.class.members)
      end

      collection = instance_exec(applicant, &collection_method)

      unless collection.kind_of?(ActiveRecord::Relation)
        raise("expected EffectiveMemberships.applicant_endorsements_endorsers_collection to return an ActiveRecord::Relation.")
      end

      collection
    end

    def to_s
      'endorsement'
    end

    def email
      endorser&.email || endorser_email
    end

    def notify!
      raise('expected endorsement email') unless email.present?

      EffectiveMemberships.send_email(:applicant_endorsement_notification, self)
      update!(last_notified_at: Time.zone.now)
    end

    def complete!
      completed!
      applicant.save!
    end

  end

end
