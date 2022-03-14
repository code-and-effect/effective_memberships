# Dashboard Fee Payments
class EffectiveFeePaymentsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :token, visible: false
    col :created_at, visible: false

    col :user
    col :organization

    col :status, visible: false
    col :submitted_at, label: 'Submitted', as: :date
    col :period, visible: false

    col :orders, action: :show

    actions_col(new: false)
  end

  collection(apply_belongs_to: false) do
    scope = EffectiveMemberships.FeePayment.deep.done.for(current_user)
  end

end
