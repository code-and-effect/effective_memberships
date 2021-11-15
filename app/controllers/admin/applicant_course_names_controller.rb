module Admin
  class ApplicantCourseNamesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    private

    def permitted_params
      params.require(:effective_applicant_course_name).permit!
    end

  end
end
