# Dashboard Applicants
class EffectiveApplicantsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :id, visible: false

    col :created_at, label: 'Created', as: :date, visible: false
    col :updated_at, label: 'Updated', as: :date, visible: false

    col :submitted_at, label: 'Submitted', visible: false, as: :date
    col :completed_at, label: 'Completed GEM', as: :date
    col :reviewed_at, label: 'Reviewed', as: :date
    col :approved_at, label: 'Approved', visible: false, as: :date

    col :orders
    col :membership_category
    col :status

    actions_col(show: false) do |applicant|
      if applicant.in_progress?
        link_to 'Continue', effective_memberships.applicant_build_path(applicant, applicant.next_step), class: 'btn btn-outline-primary', 'data-turbolinks' => false
      else
        link_to 'Show', effective_memberships.applicant_path(applicant), class: 'btn btn-outline-primary'
      end
    end
  end

  collection do
    EffectiveMemberships.applicant_class.deep
  end

end
