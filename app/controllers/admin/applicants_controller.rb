module Admin
  class ApplicantsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.applicant_class.deep }
    datatable -> { Admin::EffectiveApplicantsDatatable.new }

    submit :approve, 'Approve Applicant', success: -> {
      [
        "Successfully approved #{resource.user} #{resource}",
        ("and sent #{resource.user.email} a notification" unless resource.email_form_skip)
      ].compact.join(' ')
    }

    submit :decline, 'Decline Applicant', success: -> {
      [
        "Successfully declined #{resource.user} #{resource}",
        ("and sent #{resource.user.email} a notification" unless resource.email_form_skip)
      ].compact.join(' ')
    }

    private

    def permitted_params
      params.require(:applicant).permit!
    end

  end
end
