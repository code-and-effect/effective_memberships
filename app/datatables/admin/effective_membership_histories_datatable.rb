module Admin
  class EffectiveMembershipHistoriesDatatable < Effective::Datatable
    datatable do
      order :id, :desc

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :start_on
      col :end_on

      col :user
      col :membership_category

      col :number

      col :bad_standing
      col :removed

      actions_col
    end

    collection do
      scope = Effective::MembershipHistory.deep.all
      scope = scope.where(user_id: attributes[:user_id]) if attributes[:user_id]
      scope
    end

  end
end
