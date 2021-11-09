# For the applicant complete step to add additional applicants
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

    actions_col(show: false)
  end

  collection do
    ApplicantReference.where(applicant: applicant)
  end

  def applicant
    @applicant ||= EffectiveMemberships.applicant_class.where(id: attributes[:applicant_id]).first!
  end

end
