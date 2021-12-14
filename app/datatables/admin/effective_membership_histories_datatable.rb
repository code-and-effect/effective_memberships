module Admin
  class EffectiveMembershipHistoriesDatatable < Effective::Datatable
    datatable do
      order :id, :desc

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :start_on
      col :end_on

      col :owner
      col :membership_category

      col :number

      col :bad_standing
      col :removed

      actions_col
    end

    collection do
      scope = Effective::MembershipHistory.deep.all
      scope = scope.where(owner_id: attributes[:owner_id]) if attributes[:owner_id]
      scope = scope.where(owner_id: attributes[:user_id]) if attributes[:user_id]
      scope = scope.where(owner_id: attributes[:organization_id]) if attributes[:organization_id]
      scope
    end

  end
end
