module Admin
  class EffectiveOrganizationsDatatable < Effective::Datatable
    datatable do

      col :updated_at, visible: false
      col :created_at, visible: false

      col :id, visible: false

      if categories.present?
        col :category, search: categories
      end

      col :title

      col :representatives_count
      col :representatives

      actions_col
    end

    collection do
      EffectiveMemberships.Organization.deep.all
    end

    def categories
      EffectiveMemberships.Organization.categories
    end

  end
end
