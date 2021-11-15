class EffectiveApplicantCoursesDatatable < Effective::Datatable
  datatable do
    length :all

    col :applicant_course_area

    if applicant.has_completed_step?(:course_amounts)
      col :applicant_course_name, label: 'Course'
      col :amount
    end

    if applicant.has_completed_step?(:courses)
      col :title, visible: false, label: 'Course'
      col :code, visible: false
      col :description, visible: false
    end

  end

  collection do
    Effective::ApplicantCourse.deep.where(applicant: applicant)
      .joins(:applicant_course_area)
      .joins(:applicant_course_name)
      .order('applicant_course_areas.position, applicant_course_names.position, applicant_courses.title')
  end

  def applicant
    @applicant ||= EffectiveMemberships.applicant_class.where(id: attributes[:applicant_id]).first!
  end
end
