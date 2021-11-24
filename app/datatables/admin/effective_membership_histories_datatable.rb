module Admin
  class EffectiveMembershipHistoriesDatatable < Effective::Datatable
    datatable do
      order :start_on

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :period, visible: false
      col :start_on
      col :end_on

      col :user
      col :membership_category

      col :number
      col :in_good_standing

      actions_col
    end

    collection do
      scope = Effective::MembershipHistory.deep.all
      scope = scope.where(user_id: attributes[:user_id]) if attributes[:user_id]
      scope
    end

  end
end
