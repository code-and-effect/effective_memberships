module Admin
  class EffectiveFeePaymentsDatatable < Effective::Datatable
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

      col :period, visible: false
      col :submitted_at, label: 'Submitted', visible: false, as: :date

      col :user
      col :organization

      col :category, search: { collection: EffectiveMemberships.Category.all, polymorphic: false }

      col :orders, visible: false

      actions_col
    end

    collection(apply_belongs_to: false) do
      fee_payments = EffectiveMemberships.FeePayment.deep.all

      raise('expected an user_id but was given an owner_id') if attributes[:owner_id].present?

      if fee_payments == :in_progress && attributes[:user_id].blank? && attributes[:organization_id].blank?
        fee_payments = fee_payments.where.not(status: :draft)
      end

      if attributes[:user_id].present?
        fee_payments = fee_payments.where(user_id: attributes[:user_id])
      end

      if attributes[:organization_id].present?
        fee_payments = fee_payments.where(organization_id: attributes[:organization_id])
      end

      if attributes[:except_id].present?
        fee_payments = fee_payments.where.not(id: attributes[:except_id])
      end

      fee_payments
    end

  end
end
