module Admin
  class EffectiveFeesDatatable < Effective::Datatable
    filters do
      scope :all
      scope :purchased
      scope :not_purchased
    end

    datatable do
      order :id, :desc

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      unless attributes[:user_id] || attributes[:owner_id] || attributes[:organization_id] || attributes[:applicant_id] || attributes[:fee_payment_id]
        col :owner
      end

      unless attributes[:applicant_id] || attributes[:fee_payment_id]
        col :parent, search: :string, visible: false
      end

      col :category, search: EffectiveMemberships.fee_categories
      col :price, as: :price
      col :purchased?, as: :boolean

      col :membership_category, search: { collection: EffectiveMemberships.MembershipCategory.all, polymorphic: false }

      aggregate :total

      if attributes[:applicant_id]
        actions_col(new: false)
      else
        actions_col
      end
    end

    collection do
      scope = Effective::Fee.deep.all

      if attributes[:user_id]
        scope = scope.where(owner_id: attributes[:user_id])
      end

      if attributes[:organization_id]
        scope = scope.where(owner_id: attributes[:organization_id])
      end

      if attributes[:owner_id]
        scope = scope.where(owner_id: attributes[:owner_id])
      end

      if attributes[:applicant_id]
        scope = scope.where(parent: applicant)
      end

      if attributes[:fee_payment_id]
        scope = scope.where(parent: fee_payment)
      end

      scope
    end

    def applicant
      @applicant ||= EffectiveMemberships.Applicant.find(attributes[:applicant_id])
    end

    def fee_payment
      @fee_payment ||= EffectiveMemberships.FeePayment.find(attributes[:fee_payment_id])
    end

  end
end
