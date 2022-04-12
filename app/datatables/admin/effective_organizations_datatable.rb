module Admin
  class EffectiveOrganizationsDatatable < Effective::Datatable
    filters do
      scope :unarchived, label: 'All'
      scope :members
      scope :archived
    end

    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false

      col :id, visible: false

      if categories.present?
        col :category, search: categories
      end

      col(:to_s, label: 'Organization', sql_column: true, action: :edit)
      .search do |collection, term|
        collection.where(id: effective_resource.search_any(term))
      end.sort do |collection, direction|
        collection.order(title: direction)
      end

      col :title, visible: false

      col 'membership.joined_on'
      col 'membership.fees_paid_through_period', label: 'Fees Paid Through'
      col 'membership.categories'

      col :representatives_count
      col :representatives

      col :email, visible: false

      col :address1, visible: false do |organization|
        organization.billing_address&.address1
      end
      col :address2, visible: false do |organization|
        organization.billing_address&.address2
      end
      col :city, visible: false do |organization|
        organization.billing_address&.city
      end
      col :state_code, label: 'Prov', visible: false do |organization|
        organization.billing_address&.state_code
      end
      col :postal_code, label: 'Postal', visible: false do |organization|
        organization.billing_address&.postal_code
      end
      col :country_code, label: 'Country', visible: false do |organization|
        organization.billing_address&.country_code
      end

      col :phone, visible: false
      col :fax, visible: false
      col :website, visible: false
      col :category, visible: false
      col :notes, visible: false

      actions_col
    end

    collection do
      EffectiveMemberships.Organization.deep.left_joins(:membership).includes(:addresses, membership: :membership_categories)
    end

    def categories
      EffectiveMemberships.Organization.categories
    end

  end
end
