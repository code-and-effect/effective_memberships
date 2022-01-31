module Effective
  class FeePaymentsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::WizardController

    resource_scope -> { EffectiveMemberships.FeePayment.deep.where(owner: current_user.effective_memberships_owners) }

  end
end
