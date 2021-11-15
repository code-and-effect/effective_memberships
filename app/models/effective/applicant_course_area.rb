module Effective
  class ApplicantCourseArea < ActiveRecord::Base
    log_changes if respond_to?(:log_changes)

    has_rich_text :body

    has_many :applicant_course_names, dependent: :delete_all
    accepts_nested_attributes_for :applicant_course_names

    effective_resource do
      title          :string
      position       :integer

      timestamps
    end

    scope :deep, -> { with_rich_text_body }
    scope :sorted, -> { order(:position) }

    before_validation do
      self.position ||= (self.class.pluck(:position).compact.max || -1) + 1
    end

    validates :title, presence: true, uniqueness: true

    def to_s
      title || 'course area'
    end

  end
end
