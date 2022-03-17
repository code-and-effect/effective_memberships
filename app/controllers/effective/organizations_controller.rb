module Effective
  class OrganizationsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.Organization.deep.where(id: current_user.organizations) }

    private

    def permitted_params
      params.require(:organization).permit!
    end

  end
end
