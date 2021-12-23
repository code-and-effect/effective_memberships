module Admin
  class EffectiveMembershipHistoriesDatatable < Effective::Datatable
    datatable do
      order :id, :desc

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :start_on
      col :end_on

      col :owner

      col :number

      col :categories, label: 'Category' do |history|
        history.categories.map.with_index do |category, index|
          category_id = history.category_ids[index]
          link = link_to(category, effective_memberships.edit_admin_category_path(category_id))

          content_tag(:div, link, class: 'col-resource_item')
        end.join.html_safe
      end

      col :category_ids, visible: false

      col :bad_standing
      col :removed

      actions_col
    end

    collection do
      raise('expected an owner_id, not user_id') if attributes[:user_id].present?

      scope = Effective::MembershipHistory.deep.all
      scope = scope.where(owner_id: attributes[:owner_id]) if attributes[:owner_id]
      scope
    end

  end
end
