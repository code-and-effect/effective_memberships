# For the applicant complete step to add additional references
class EffectiveApplicantReferencesDatatable < Effective::Datatable

  datatable do
    order :name

    col :name
    col :email
    col :phone

    col :status do |reference|
      if reference.submitted?
        'Waiting on response'
      elsif reference.completed?
        'Completed'
      end
    end

    col :last_notified_at do |reference|
      reference.last_notified_at&.strftime('%F') unless reference.completed?
    end

    actions_col partial: 'effective/applicant_references/datatable_actions', partial_as: :applicant_reference
  end

  collection do
    Effective::ApplicantReference.deep.where(applicant: applicant)
  end

  def applicant
    @applicant ||= EffectiveMemberships.Applicant.where(id: attributes[:applicant_id]).first!
  end

end
