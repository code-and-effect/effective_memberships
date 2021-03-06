module Effective
  class ApplicantReferencesController < ApplicationController
    include Effective::CrudController

    page_title 'Confidential Reference Form'

    # The show and update actions are public routes but can only be reached by the token.
    # The reference must declare and submit the form
    # To move an applicant reference from submitted to completed

    submit :notify, 'Resend email notification',
      success: -> { "Sent email notification to #{resource.email}" }

    submit :complete, 'Complete Reference'

    def show
      @applicant_reference = ApplicantReference.submitted.find(params[:id])
      EffectiveResources.authorize!(self, :show, @applicant_reference)

      render 'edit'
    end

    protected

    def permitted_params
      permitted = params.require(:effective_applicant_reference).permit!.except(:token, :last_notified_at, :status, :status_steps, :applicant_id)

      if current_user && current_user.memberships_owners.include?(resource.applicant&.owner)
        permitted.except(:reservations, :reservations_reason, :work_history, :accept_declaration)
      else
        permitted
      end

    end

  end
end
