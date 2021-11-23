module Effective
  class FeePayment < ActiveRecord::Base
    self.table_name = EffectiveMemberships.fee_payments_table_name.to_s

    effective_memberships_fee_payment
  end
end
