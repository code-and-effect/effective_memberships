module Admin
  class EffectiveCategoriesDatatable < Effective::Datatable
    datatable do
      reorder :position

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :title
      col :applicant_fee, as: :price
      col :renewal_fee, as: :price
      col :late_fee, as: :price
      col :rich_text_body, label: 'Body'
      col :tax_exempt
      col :qb_item_name, visible: false

      actions_col
    end

    collection do
      EffectiveMemberships.Category.deep.all
    end
  end
end
