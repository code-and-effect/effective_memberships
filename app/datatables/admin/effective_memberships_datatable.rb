module Admin
  class EffectiveMembershipsDatatable < Effective::Datatable

    datatable do
      order :id
      col :id, visible: false

      col :owner_id, visible: false
      col :owner_type, visible: false

      val :owner
      col :categories

      col :number
      col :number_as_integer, visible: false

      col :joined_on
      col :registration_on

      col :fees_paid_period, visible: false, label: 'Fees Paid'
      col :fees_paid_through_period, label: 'Fees Paid Through'

      col :bad_standing
      col :bad_standing_admin, visible: false
      col :bad_standing_reason, visible: false

      col :email do |membership|
        email = membership.owner.try(:email)
        mail_to(email) if email.present?
      end

      col :phone do |membership|
        membership.owner.try(:phone) || membership.owner.try(:home_phone) || membership.owner.try(:cell_phone)
      end

      col :address do |membership|
        membership.owner.try(:addresses).try(:first).try(:to_html)
      end

      col :address1, visible: false do |membership|
        membership.owner.try(:addresses).try(:first).try(:address1)
      end

      col :address2, visible: false do |membership|
        membership.owner.try(:addresses).try(:first).try(:address2)
      end

      col :city, visible: false do |membership|
        membership.owner.try(:addresses).try(:first).try(:city)
      end

      col :province, visible: false do |membership|
        membership.owner.try(:addresses).try(:first).try(:province)
      end

      col :country, visible: false do |membership|
        membership.owner.try(:addresses).try(:first).try(:country)
      end

      col :postal_code, visible: false do |membership|
        membership.owner.try(:addresses).try(:first).try(:postal_code)
      end

      actions_col
    end

    collection do
      memberships = Effective::Membership.deep.all.includes(owner: :addresses)

      raise('expected an owner_id, not user_id') if attributes[:user_id].present?

      if attributes[:owner_id].present?
        memberships = memberships.where(owner_id: attributes[:owner_id])
      end

      memberships
    end

  end
end
