module Effective
  class FeePaymentsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::WizardController

    resource_scope -> { EffectiveMemberships.FeePayment.deep.where(user: current_user) }
  end
end
