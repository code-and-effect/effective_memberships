module Admin
  class OrganizationsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.Organization.deep.all }
    datatable -> { EffectiveResources.best('Admin::EffectiveOrganizationsDatatable').new }

    private

    def permitted_params
      model = (params.key?(:effective_organization) ? :effective_organization : :organization)
      params.require(model).permit!
    end

  end
end
