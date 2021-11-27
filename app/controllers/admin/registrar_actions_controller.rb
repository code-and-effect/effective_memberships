module Admin
  class RegistrarActionsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController
    resource_scope -> { Effective::RegistrarAction }

    submit :bad_standing, 'Set In Bad Standing',
      success: -> { "#{resource.user} is now In Bad Standing" },
      redirect: -> { admin_users_path(resource) }

    submit :good_standing, 'Remove In Bad Standing',
      success: -> { "#{resource.user} is now In Good Standing" },
      redirect: -> { admin_users_path(resource) }

    after_error do
      flash[:danger] = resource_flash(:danger, resource, commit_action[:action])
      redirect_to admin_users_path(resource)
    end

    private

    def permitted_params
      params.require(:effective_registrar_action).permit!
    end

    def admin_users_path(resource)
      "/admin/users/#{resource.user.to_param}/edit"
    end

  end
end
