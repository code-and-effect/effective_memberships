module Admin
  class RegistrarActionsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController
    resource_scope -> { Effective::RegistrarAction }

    submit :register, 'Register',
      success: -> { "#{resource.owner} is now a #{resource.owner.membership.category} member" },
      redirect: -> { admin_owners_path(resource) }

    submit :reclassify, 'Reclassify',
      success: -> { "#{resource.owner} has been reclassified to #{resource.owner.membership.category}" },
      redirect: -> { admin_owners_path(resource) }

    submit :assign, 'Assign',
      success: -> { "#{resource.owner} has been assigned to #{resource.owner.membership.categories.to_sentence}" },
      redirect: -> { admin_owners_path(resource) }

    submit :remove, 'Remove',
      success: -> { "#{resource.owner} has been removed" },
      redirect: -> { admin_owners_path(resource) }

    submit :bad_standing, 'Set In Bad Standing',
      success: -> { "#{resource.owner} is now In Bad Standing" },
      redirect: -> { admin_owners_path(resource) }

    submit :good_standing, 'Remove In Bad Standing',
      success: -> { "#{resource.owner} is now In Good Standing" },
      redirect: -> { admin_owners_path(resource) }

    submit :fees_paid, 'Mark Fees Paid',
      success: -> { "#{resource.owner} has now paid their fees through #{resource.owner.membership.fees_paid_through_period&.strftime('%F')}" },
      redirect: -> { admin_owners_path(resource) }

    after_error do
      flash.keep
      redirect_to admin_owners_path(resource)
    end

    private

    def permitted_params
      params.require(:effective_registrar_action).permit!
    end

    def admin_owners_path(resource)
      Effective::Resource.new(resource.owner, namespace: :admin).action_path(:edit)
    end

  end
end
