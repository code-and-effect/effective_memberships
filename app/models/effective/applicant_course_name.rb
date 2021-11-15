module Effective
  class ApplicantCourseName < ActiveRecord::Base
    log_changes(to: :applicant_course_area) if respond_to?(:log_changes)

    belongs_to :applicant_course_area

    effective_resource do
      title          :string
      position       :integer

      timestamps
    end

    scope :deep, -> { all }
    scope :sorted, -> { order(:position) }

    before_validation(if: -> { applicant_course_area.present? }) do
      self.position ||= (applicant_course_area.applicant_course_names.map(&:position).compact.max || -1) + 1
    end

    validates :title, presence: true, uniqueness: true
    validates :position, presence: true

    def to_s
      title || 'course name'
    end

  end
end
