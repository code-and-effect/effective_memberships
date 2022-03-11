module Admin
  class RepresentativesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { Effective::Representative.deep.all }
    datatable -> { Admin::EffectiveRepresentativesDatatable.new }

    private

    def permitted_params
      model = (params.key?(:effective_representative) ? :effective_representative : :representative)
      params.require(model).permit!
    end

  end
end
