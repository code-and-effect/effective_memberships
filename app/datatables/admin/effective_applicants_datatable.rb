module Admin
  class EffectiveApplicantsDatatable < Effective::Datatable
    filters do
      scope :all
      scope :in_progress, label: 'Open / Active'
      scope :done, label: 'Done'
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

      col(:user).search do |collection, term|
        collection.where(user_id: User.search_col(term))
      end

      col :category
      col :membership_category, search: { collection: EffectiveMemberships.MembershipCategory.all, polymorphic: false }
      col :from_membership_category, search: { collection: EffectiveMemberships.MembershipCategory.all, polymorphic: false }, visible: false

      col :orders, visible: false

      actions_col
    end

    collection do
      applicants = EffectiveMemberships.Applicant.deep.all

      if scope == :in_progress && attributes[:user_id].blank?
        applicants = applicants.where.not(status: :draft)
      end

      if attributes[:user_id].present?
        applicants = applicants.where(user_id: attributes[:user_id])
      end

      if attributes[:except_id].present?
        applicants = applicants.where.not(id: attributes[:except_id])
      end

      applicants
    end

  end
end
