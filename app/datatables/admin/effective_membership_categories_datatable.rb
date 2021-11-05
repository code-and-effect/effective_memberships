module Admin
  class EffectiveMembershipCategoriesDatatable < Effective::Datatable
    datatable do
      reorder :position

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :title
      col :applicant_fee, as: :price
      col :annual_fee, as: :price

      actions_col
    end

    collection do
      EffectiveMemberships.membership_category_class.deep.all
    end
  end
end
