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
      col :rich_text_body, label: 'Body'

      actions_col
    end

    collection do
      EffectiveMemberships.MembershipCategory.deep.all
    end
  end
end
