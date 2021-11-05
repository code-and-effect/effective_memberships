module Admin
  class EffectiveApplicantsDatatable < Effective::Datatable
    filters do
      scope :in_progress, label: 'Open / Active'
      scope :done, label: 'Done'
      scope :all
    end

    datatable do
      order :id
      col :id, visible: false

      col(:user).search do |collection, term|
        collection.where(user_id: User.search_col(term))
      end

      # col(:summary, label: 'Reviews <small>Academic & Credential</small>'.html_safe, partial: 'admin/applicants/col')

      col :membership_category, label: 'FROM GEM'
      col :from_membership_category, visible: false

      col :orders, visible: false

      actions_col
    end

    collection do
      applicants = EffectiveMemberships.applicant_class.deep.all

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
