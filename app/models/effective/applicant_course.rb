module Effective
  class ApplicantCourse < ActiveRecord::Base
    log_changes(to: :applicant) if respond_to?(:log_changes)

    belongs_to :applicant_course_area

    belongs_to :applicant, polymorphic: true, optional: true
    belongs_to :applicant_course_name, optional: true

    effective_resource do
      title          :string
      amount         :integer

      code           :string
      description    :text

      timestamps
    end

    scope :deep, -> { includes(:applicant_course_area, :applicant_course_name, :applicant) }
    scope :sorted, -> { order(:title) }

    before_validation(if: -> { applicant_course_name.present? }) do
      self.title = applicant_course_name.title
      self.applicant_course_area = applicant_course_name.applicant_course_area
    end

    validates :title, presence: true

    with_options(if: -> { applicant_course_name.blank? }) do
      validates :code, presence: true
      validates :description, presence: true
    end

    def to_s
      title || 'course'
    end

  end
end
