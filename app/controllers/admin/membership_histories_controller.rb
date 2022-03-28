module Admin
  class MembershipHistoriesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController

    submit :save, 'Update History',
      success: -> { "Membership history successfully updated. Please double check the history is correct." },
      redirect: -> { admin_owners_path(resource) }

    private

    def permitted_params
      model = (params.key?(:effective_membership_history) ? :effective_membership_history : :membership_history)
      params.require(model).permit!
    end

    def admin_owners_path(resource)
      Effective::Resource.new(resource.owner, namespace: :admin).action_path(:edit) + '?tab=membership'
    end

  end
end
