module Effective
  class ApplicantsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::WizardController

    resource_scope -> { EffectiveMemberships.Applicant.deep.where(owner: current_user.effective_memberships_owners) }

    # Allow only 1 in-progress application at a time
    before_action(only: [:new, :show], unless: -> { resource&.done? }) do
      existing = resource_scope.in_progress.where.not(id: resource).first

      if existing.present?
        flash[:success] = "You have been redirected to your existing in progress application"
        redirect_to effective_memberships.applicant_build_path(existing, existing.next_step)
      end
    end


    after_save do
      flash.now[:success] = ''
    end

    private

    def permitted_params
      params.require(:applicant).permit!.except(
        :owner_id, :owner_type, :status, :status_steps, :wizard_steps,
        :submitted_at, :completed_at, :reviewed_at, :approved_at,
        :declined_at, :declined_reason, :created_at, :updated_at
      )
    end

  end
end
