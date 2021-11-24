module Admin
  class FeesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { Effective::Fee.deep.all }

    private

    def permitted_params
      model = (params.key?(:effective_fee) ? :effective_fee : :fee)
      params.require(model).permit!
    end

  end
end
