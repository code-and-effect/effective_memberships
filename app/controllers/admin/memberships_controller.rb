module Admin
  class MembershipsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    submit :revise, 'Update Membership',
      success: -> { "#{resource.owner} has been successfully updated. Please double check the membership history is correct" },
      redirect: -> { admin_owners_path(resource) }

    private

    def permitted_params
      model = (params.key?(:effective_membership) ? :effective_membership : :membership)
      params.require(model).permit!
    end

    def admin_owners_path(resource)
      Effective::Resource.new(resource.owner, namespace: :admin).action_path(:edit) + '?tab=membership'
    end

  end
end
