module Admin
  class EffectiveApplicantCourseAreasDatatable < Effective::Datatable
    datatable do
      reorder :position

      col :title
      col :applicant_course_names, label: 'Courses'

      actions_col
    end

    collection do
      Effective::ApplicantCourseArea.deep.all
    end

  end
end
