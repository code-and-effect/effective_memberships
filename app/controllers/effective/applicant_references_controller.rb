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
      if resource.submitted?
        params.require(:effective_applicant_reference).permit(ApplicantReference.reference_params)
      else
        params.require(:effective_applicant_reference).permit(ApplicantReference.permitted_params)
      end
    end

  end
end
