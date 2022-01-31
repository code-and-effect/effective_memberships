module Effective
  class ApplicantExperience < ActiveRecord::Base
    belongs_to :applicant, polymorphic: true

    log_changes(to: :applicant) if respond_to?(:log_changes)

    LEVELS = ['Full Time', 'Part Time', 'Volunteer']
    ONE_HUNDRED_PERCENT = 100_000

    effective_resource do
      position          :string
      employer          :string

      start_on          :date
      end_on            :date

      percent_worked    :integer  # 3 digits of precision. 50_000 == 50%
      still_work_here   :boolean

      level             :string
      tasks_performed   :text

      months            :integer

      timestamps
    end

    scope :deep, -> { includes(:applicant) }

    before_validation(if: -> { start_on.present? && end_on.present? }) do
      self.months ||= ((end_on - start_on) / 1.month).to_i
    end

    validates :position, presence: true
    validates :employer, presence: true
    validates :start_on, presence: true
    validates :end_on, presence: true
    validates :level, presence: true, inclusion: { in: LEVELS }
    validates :months, presence: true

    validates :percent_worked, presence: true,
      inclusion: { in: 0..ONE_HUNDRED_PERCENT, message: 'must be between 0 and 100%' }

    validate(if: -> { start_on.present? && end_on.present? }) do
      errors.add(:end_on, 'must be after start date') unless start_on < end_on
    end

    def to_s
      position.presence || 'work experience'
    end

    def assign_months!
      return 0 unless end_on.present? && start_on.present?

      self.percent_worked ||= (part_time? ? 0 : ONE_HUNDRED_PERCENT)

      months = ((end_on.end_of_day.to_time - start_on.to_time) / 1.month.second).ceil
      months *= (percent_worked / ONE_HUNDRED_PERCENT.to_f)

      self.months = months
    end

    def percent_worked_to_s
      (percent_worked.to_i / 1000.to_f).to_i.to_s + '%'
    end

    def full_time?
      level == 'Full Time'
    end

    def part_time?
      level == 'Part Time'
    end

    def volunteer?
      level == 'Volunteer'
    end
  end
end
