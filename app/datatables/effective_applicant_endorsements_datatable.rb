# For the applicant complete step to add additional endorsements
class EffectiveApplicantEndorsementsDatatable < Effective::Datatable

  datatable do
    order :name

    col :name do |endorsement|
      endorser&.to_s || name
    end

    col :email
    col :phone

    col :status do |reference|
      if reference.submitted?
        'Waiting on response'
      elsif reference.completed?
        'Completed'
      end
    end

    col :last_notified_at do |endorsement|
      endorsement.last_notified_at&.strftime('%F') unless endorsement.completed?
    end

    actions_col partial: 'effective/applicant_endorsements/datatable_actions', partial_as: :applicant_endorsement
  end

  collection do
    Effective::ApplicantEndorsement.deep.where(applicant: applicant)
  end

  def applicant
    @applicant ||= EffectiveMemberships.Applicant.where(id: attributes[:applicant_id]).first!
  end

end
