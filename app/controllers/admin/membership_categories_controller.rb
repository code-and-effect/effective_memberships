module Admin
  class MembershipCategoriesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.membership_category_class.deep }
    datatable -> { Admin::EffectiveMembershipCategoriesDatatable.new }

    private

    def permitted_params
      params.require(:membership_category).permit!
    end

  end
end
