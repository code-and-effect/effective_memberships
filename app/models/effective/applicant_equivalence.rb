module Effective
  class ApplicantEquivalence < ActiveRecord::Base
    belongs_to :applicant, polymorphic: true

    log_changes(to: :applicant) if respond_to?(:log_changes)

    effective_resource do
      name           :string

      start_on       :date
      end_on         :date

      notes          :text

      timestamps
    end

    scope :deep, -> { all }

    validates :name, presence: true
    validates :start_on, presence: true

    validate(if: -> { start_on.present? && end_on.present? }) do
      errors.add(:end_on, 'must be after start date') unless start_on < end_on
    end

    def to_s
      name || 'equivalence'
    end

  end
end
