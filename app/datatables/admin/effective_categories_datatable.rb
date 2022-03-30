module Admin
  class EffectiveCategoriesDatatable < Effective::Datatable
    datatable do
      reorder :position

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :title
      col :can_apply_new, label: 'Can Apply'
      col :applicant_fee, as: :price

      col :renewal_fee, as: :price
      col :late_fee, as: :price
      col :rich_text_body, label: 'Body'
      col :tax_exempt
      col :qb_item_name, visible: false

      col :create_renewal_fees, visible: false
      col :create_late_fees, visible: false
      col :create_bad_standing, visible: false

      col :category_type, search: EffectiveMemberships.Category.category_types

      col :optional_applicant_wizard_steps, label: 'Applicant Steps'
      col :optional_fee_payment_wizard_steps, label: 'Fee Payment Steps'

      actions_col
    end

    collection do
      EffectiveMemberships.Category.deep.all
    end
  end
end
