class Admin::EffectiveApplicantReferencesDatatable < Effective::Datatable

  datatable do
    order :name

    col :applicant

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

    actions_col
  end

  collection do
    Effective::ApplicantReference.deep.all
  end

end
