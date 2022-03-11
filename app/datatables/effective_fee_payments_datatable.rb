# Dashboard Fee Payments
class EffectiveFeePaymentsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :token, visible: false
    col :created_at, visible: false

    col :owner
    col :status, visible: false
    col :submitted_at, label: 'Submitted', as: :date
    col :period, visible: false

    col :orders, action: :show

    actions_col(new: false)
  end

  collection do
    scope = EffectiveMemberships.FeePayment.deep.done.for(current_user)
  end

end
