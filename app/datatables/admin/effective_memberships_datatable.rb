module Admin
  class EffectiveMembershipsDatatable < Effective::Datatable

    datatable do
      order :id
      col :id, visible: false

      col :owner_id, visible: false
      col :owner_type, visible: false

      col :owner
      col :categories

      col :number
      col :number_as_integer, visible: false

      col :joined_on
      col :registration_on

      col :fees_paid_period, visible: false, label: 'Fees Paid'
      col :fees_paid_through_period, label: 'Fees Paid Through'

      col :bad_standing
      col :bad_standing_admin, visible: false
      col :bad_standing_reason, visible: false

      actions_col
    end

    collection do
      memberships = Effective::Membership.deep.all

      raise('expected an owner_id, not user_id') if attributes[:user_id].present?

      if attributes[:owner_id].present?
        memberships = memberships.where(owner_id: attributes[:owner_id])
      end

      memberships
    end

  end
end
