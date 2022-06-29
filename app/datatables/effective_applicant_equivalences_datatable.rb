class EffectiveApplicantEquivalencesDatatable < Effective::Datatable
  datatable do
    length :all
    order :start_on

    col :start_on

    col :end_on do |applicant_equivalence|
      applicant_equivalence.end_on&.strftime('%F') || '-'
    end

    col :name
    col :notes
  end

  collection do
    Effective::ApplicantEquivalence.deep.where(applicant: applicant)
  end

  def applicant
    @applicant ||= EffectiveMemberships.Applicant.where(id: attributes[:applicant_id]).first!
  end
end
