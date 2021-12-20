# Dashboard Fee Payments
class EffectiveFeePaymentsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :token, visible: false
    col :created_at, visible: false

    col :status
    col :period, visible: false
    col :submitted_at, label: 'Submitted', as: :date

    col :orders

    actions_col(show: false) do |fee_payment|
      if fee_payment.draft?
        dropdown_link_to('Continue', effective_memberships.fee_payment_build_path(fee_payment, fee_payment.next_step), 'data-turbolinks' => false)
        dropdown_link_to('Delete', effective_memberships.fee_payment_path(fee_payment), 'data-confirm': "Really delete #{fee_payment}?", 'data-method': :delete)
      else
        dropdown_link_to('Show', effective_memberships.fee_payment_path(fee_payment))
      end
    end
  end

  collection do
    EffectiveMemberships.FeePayment.deep.where(owner: current_user.effective_memberships_owner)
  end

end
