# Dashboard Applicants
class EffectiveApplicantsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :id, visible: false

    col :category, label: 'Category'
    col :status

    col :created_at, label: 'Created', as: :date
    col :updated_at, label: 'Updated', as: :date, visible: false
    col :submitted_at, label: 'Submitted', as: :date
    col :completed_at, label: 'Completed', as: :date
    col :reviewed_at, label: 'Reviewed', as: :date
    col :approved_at, label: 'Approved', visible: false, as: :date

    col :orders

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
    EffectiveMemberships.Applicant.deep.where(owner: current_user.effective_memberships_owner)
  end

end
