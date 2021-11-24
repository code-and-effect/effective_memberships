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

      unless attributes[:user_id] || attributes[:applicant_id] || attributes[:fee_payment_id]
        col :user
      end

      unless attributes[:applicant_id] || attributes[:fee_payment_id]
        col :parent, search: :string
      end

      col :category, search: EffectiveMemberships.fee_categories
      col :period
      col :price, as: :price
      col :purchased?, as: :boolean

      col :membership_category

      if attributes[:applicant_id]
        actions_col(new: false)
      else
        actions_col
      end
    end

    collection do
      scope = Effective::Fee.deep.all

      if attributes[:user_id]
        scope = scope.where(user_id: attributes[:user_id])
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
