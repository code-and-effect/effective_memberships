module Admin
  class RegistrarActionsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_memberships) }

    include Effective::CrudController
    resource_scope -> { Effective::RegistrarAction }

    after_save do
      flash[:success] = resource_flash(:success, resource, commit_action[:action])
      redirect_to("/admin/users/#{resource.user.to_param}/edit")
    end

    after_error do
      flash[:danger] = resource_flash(:danger, resource, commit_action[:action])
      redirect_to("/admin/users/#{resource.user.to_param}/edit")
    end

    submit :bad_standing, 'Set In Bad Standing'
    submit :good_standing, 'Remove In Bad Standing'

    private

    def permitted_params
      params.require(:effective_registrar_action).permit!
    end

  end
end
