module Admin
  class EffectiveApplicantsDatatable < Effective::Datatable
    filters do
      scope :not_draft, label: 'All'
      scope :in_progress, label: 'Open / Active'
      scope :done, label: 'Done'
      scope :draft
    end

    datatable do
      order :id
      col :id, visible: false

      col :status

      col :created_at, label: 'Created', as: :date, visible: false
      col :updated_at, label: 'Updated', visible: false

      col :submitted_at, label: 'Submitted', visible: false, as: :date
      col :completed_at, label: 'Completed', visible: false, as: :date
      col :reviewed_at, label: 'Reviewed', visible: false, as: :date
      col :approved_at, label: 'Approved', visible: false, as: :date

      col :owner

      col :applicant_type
      col :category, search: { collection: EffectiveMemberships.Category.all, polymorphic: false }
      col :from_category, search: { collection: EffectiveMemberships.Category.all, polymorphic: false }, visible: false

      col :orders, visible: false

      actions_col
    end

    collection do
      applicants = EffectiveMemberships.Applicant.deep.all

      raise('expected an owner_id, not user_id') if attributes[:user_id].present?

      if scope == :in_progress && attributes[:owner_id].blank?
        applicants = applicants.where.not(status: :draft)
      end

      if attributes[:owner_id].present?
        applicants = applicants.where(owner_id: attributes[:owner_id])
      end

      if attributes[:except_id].present?
        applicants = applicants.where.not(id: attributes[:except_id])
      end

      applicants
    end

  end
end
