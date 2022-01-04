module Admin
  class FeePaymentsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.FeePayment.deep.all }
    datatable -> { Admin::EffectiveFeePaymentsDatatable.new }

    private

    def permitted_params
      model = (params.key?(:effective_fee_payment) ? :effective_fee_payment : :fee_payment)
      params.require(model).permit!
    end

  end
end
