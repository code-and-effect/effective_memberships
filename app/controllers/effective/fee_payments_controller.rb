module Effective
  class FeePaymentsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::WizardController

    resource_scope -> { EffectiveMemberships.FeePayment.deep.where(user: current_user) }

    # Allow only 1 in-progress fee payment at a time
    before_action(only: [:new, :show], unless: -> { resource&.done? }) do
      existing = resource_scope.in_progress.where.not(id: resource).first

      if existing.present?
        flash[:success] = "You have been redirected to your existing in progress fee payment"
        redirect_to effective_memberships.fee_payment_build_path(existing, existing.next_step)
      end
    end

    private

    def permitted_params
      params.require(:fee_payment).permit!.except(
        :user_id, :status, :status_steps, :wizard_steps,
        :submitted_at
      )
    end

  end
end
