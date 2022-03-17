class EffectiveRepresentativesDatatable < Effective::Datatable
  datatable do
    col :id, visible: false

    col :organization
    col :user

    unless attributes[:user_id]
      col :email do |representative|
        mail_to(representative.user.email)
      end
    end

    col :roles, search: roles_collection

    unless attributes[:actions] == false
      actions_col
    end

  end

  collection do
    scope = Effective::Representative.deep.all.where(organization: current_user.organizations)

    if attributes[:organization_id]
      scope = scope.where(organization_id: attributes[:organization_id])
    end

    if attributes[:user_id]
      scope = scope.where(user_id: attributes[:user_id])
    end

    scope
  end

  def roles_collection
    EffectiveRoles.roles_collection(Effective::Representative.new).map(&:second)
  end

end
