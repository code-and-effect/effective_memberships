module Admin
  class EffectiveApplicantCourseNamesDatatable < Effective::Datatable
    datatable do
      reorder :position

      col :applicant_course_area, label: 'Course Area'
      col :title

      actions_col
    end

    collection do
      Effective::ApplicantCourseName.deep
    end

  end
end
