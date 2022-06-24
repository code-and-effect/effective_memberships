module Effective
  class ApplicantEndorsementsController < ApplicationController
    include Effective::CrudController
    include Effective::Select2AjaxController

    page_title 'Confidential Endorsement Form'

    # The show and update actions are public routes but can only be reached by the token.
    # The endorser must declare and submit the form
    # To move an applicant endorsement from submitted to completed

    submit :notify, 'Resend email notification',
      success: -> { "Sent email notification to #{resource.email}" }

    submit :complete, 'Complete Endorsement'

    def show
      @applicant_endorsement = ApplicantEndorsement.submitted.find(params[:id])
      EffectiveResources.authorize!(self, :show, @applicant_endorsement)

      render 'edit'
    end

    # Must be signed in
    def select2_ajax_endorser
      authenticate_user! if defined?(Devise)

      applicant = EffectiveMemberships.Applicant.find(params[:applicant_id])
      collection = Effective::ApplicantEndorsement.endorser_collection(applicant)

      respond_with_select2_ajax(collection)
    end

    protected

    def permitted_params
      permitted = params.require(:effective_applicant_endorsement).permit!.except(:token, :last_notified_at, :status, :status_steps, :applicant_id, :endorser_id)

      if current_user && current_user.memberships_owners.include?(resource.applicant&.owner)
        permitted.except(:notes, :accept_declaration)
      else
        permitted
      end

    end

  end
end
