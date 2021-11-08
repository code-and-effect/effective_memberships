module Admin
  class ApplicantsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.applicant_class.deep }
    datatable -> { Admin::EffectiveApplicantsDatatable.new }

    private

    def permitted_params
      params.require(:applicant).permit!
    end

  end
end
