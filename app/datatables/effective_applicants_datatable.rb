# Dashboard Applicants
class EffectiveApplicantsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :id, visible: false

    col :created_at, label: 'Created', as: :date, visible: false
    col :updated_at, label: 'Updated', as: :date, visible: false

    col :submitted_at, label: 'Submitted', visible: false, as: :date
    col :completed_at, label: 'Completed', as: :date
    col :reviewed_at, label: 'Reviewed', as: :date
    col :approved_at, label: 'Approved', visible: false, as: :date

    col :orders
    col :membership_category
    col :status

    actions_col(show: false) do |applicant|
      if applicant.draft?
        dropdown_link_to('Continue', effective_memberships.applicant_build_path(applicant, applicant.next_step), 'data-turbolinks' => false)
        dropdown_link_to('Delete', effective_memberships.applicant_path(applicant), 'data-confirm': "Really delete #{applicant}?", 'data-method': :delete)
      else
        dropdown_link_to('Show', effective_memberships.applicant_path(applicant))
      end
    end
  end

  collection do
    EffectiveMemberships.Applicant.deep.where(user: current_user)
  end

end
