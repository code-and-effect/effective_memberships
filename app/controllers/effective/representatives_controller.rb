module Effective
  class RepresentativesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::CrudController

    resource_scope -> {
      organizations = EffectiveMemberships.Organization.deep.where(id: current_user.organizations)
      Effective::Representative.deep.where(organization: organizations)
    }

    private

    def permitted_params
      params.require(:effective_representative).permit!
    end

  end
end
