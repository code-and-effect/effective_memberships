class EffectiveApplicantEducationsDatatable < Effective::Datatable
  datatable do
    length :all
    order :start_on

    col :start_on
    col :end_on

    col :institution
    col :location

    col :degree_obtained
  end

  collection do
    Effective::ApplicantEducation.deep.where(applicant: applicant)
  end

  def applicant
    @applicant ||= EffectiveMemberships.Applicant.where(id: attributes[:applicant_id]).first!
  end
end
