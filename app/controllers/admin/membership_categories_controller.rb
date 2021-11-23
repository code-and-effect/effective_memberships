module Admin
  class MembershipCategoriesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.MembershipCategory.deep.all }
    datatable -> { Admin::EffectiveMembershipCategoriesDatatable.new }

    private

    def permitted_params
      model = (params.key?(:effective_membership_category) ? :effective_membership_category : :membership_category)
      params.require(model).permit!
    end

  end
end
