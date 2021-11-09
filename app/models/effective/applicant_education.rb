module Effective
  class ApplicantEducation < ActiveRecord::Base
    belongs_to :applicant

    log_changes(to: :applicant) if respond_to?(:log_changes)

    effective_resource do
      start_on       :date
      end_on         :date

      institution       :string
      location          :string

      program           :string
      degree_obtained   :string

      timestamps
    end

    scope :deep, -> { includes(:applicant) }

    validates :start_on, presence: true
    validates :end_on, presence: true
    validates :institution, presence: true
    validates :location, presence: true
    validates :program, presence: true
    validates :degree_obtained, presence: true

    validate(if: -> { start_on.present? && end_on.present? }) do
      errors.add(:end_on, 'must be after start date') unless start_on < end_on
    end

    def to_s
      degree_obtained || 'education'
    end

  end
end
