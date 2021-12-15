module Admin
  class CategoriesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.Category.deep.all }
    datatable -> { Admin::EffectiveCategoriesDatatable.new }

    private

    def permitted_params
      model = (params.key?(:effective_category) ? :effective_category : :category)
      params.require(model).permit!
    end

  end
end
