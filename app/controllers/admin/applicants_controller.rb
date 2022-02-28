module Admin
  class ApplicantsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.Applicant.deep.all }
    datatable -> { Admin::EffectiveApplicantsDatatable.new }

    submit :complete, 'Complete Applicant', success: -> {
      [
        "Successfully completed #{resource.owner} #{resource}",
        ("and sent #{resource.owner.email} a notification" unless resource.email_form_skip)
      ].compact.join(' ')
    }

    submit :missing, 'Missing Info Applicant', success: -> {
      [
        "Successfully marked #{resource.owner} #{resource} as missing info",
        ("and sent #{resource.owner.email} a notification" unless resource.email_form_skip)
      ].compact.join(' ')
    }

    submit :approve, 'Approve Applicant', success: -> {
      [
        "Successfully approved #{resource.owner} #{resource}",
        ("and sent #{resource.owner.email} a notification" unless resource.email_form_skip)
      ].compact.join(' ')
    }

    submit :decline, 'Decline Applicant', success: -> {
      [
        "Successfully declined #{resource.owner} #{resource}",
        ("and sent #{resource.owner.email} a notification" unless resource.email_form_skip)
      ].compact.join(' ')
    }

    private

    def permitted_params
      model = (params.key?(:effective_applicant) ? :effective_applicant : :applicant)
      params.require(model).permit!
    end

  end
end
