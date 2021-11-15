module Admin
  class ApplicantCourseAreasController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    private

    def permitted_params
      params.require(:effective_applicant_course_area).permit!
    end

  end
end
