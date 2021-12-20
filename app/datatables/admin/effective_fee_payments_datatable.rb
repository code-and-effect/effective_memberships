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

      col :owner

      col :category, search: { collection: EffectiveMemberships.Category.all, polymorphic: false }

      col :orders, visible: false

      actions_col
    end

    collection do
      fee_payments = EffectiveMemberships.FeePayment.deep.all

      raise('expected an owner_id, not user_id') if attributes[:user_id].present?

      if fee_payments == :in_progress && attributes[:owner_id].blank?
        fee_payments = fee_payments.where.not(status: :draft)
      end

      if attributes[:owner_id].present?
        fee_payments = fee_payments.where(owner_id: attributes[:owner_id])
      end

      if attributes[:except_id].present?
        fee_payments = fee_payments.where.not(id: attributes[:except_id])
      end

      fee_payments
    end

  end
end
