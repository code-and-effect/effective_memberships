module Effective
  class Fee < ActiveRecord::Base
    acts_as_purchasable

    log_changes(to: :user) if respond_to?(:log_changes)

    # Every fee is charged to a user
    belongs_to :user, polymorphic: true

    # This fee may belong to an application or other parent model
    belongs_to :parent, polymorphic: true, optional: true

    # The membership category for this fee
    belongs_to :membership_category, polymorphic: true, optional: true

    effective_resource do
      category      :string

      title         :string

      period        :date
      due_at        :datetime

      price         :integer
      qb_item_name  :string
      tax_exempt    :boolean

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:user, :parent, :membership_category) }

    before_validation(if: -> { user.present? }) do
      additional = user.additional_fee_attributes(self)
      raise('expected a Hash of attributes') unless additional.kind_of?(Hash)
      assign_attributes(additional)
    end

    before_validation(if: -> { user.present? }) do
      self.membership_category ||= user.membership&.category
    end

    before_validation do
      self.period ||= default_period()
      self.due_at ||= default_due_at()

      self.qb_item_name ||= default_qb_item_name()
      self.tax_exempt ||= default_tax_exempt()

      self.title ||= default_title()
    end

    validates :category, presence: true
    validates :price, presence: true

    validates :title, presence: true
    validates :period, presence: true
    validates :due_at, presence: true
    validates :qb_item_name, presence: true

    validate(if: -> { category.present? }) do
      self.errors.add(:category, 'is not included') unless EffectiveMemberships.fee_categories.include?(category)
    end

    def to_s
      title.presence || 'New Fee'
    end

    def late?
      return false if due_at.blank?
      return false if purchased?

      due_at < Time.zone.now
    end

    # Used by applicant.applicant_submit_fees
    def applicant_submit_fee?
      category == 'Applicant'
    end

    def fee_payment_fee?
      category != 'Applicant'
    end

    private

    def default_period
      EffectiveMemberships.Registrar.current_period
    end

    def default_due_at
      Time.zone.now
    end

    def default_qb_item_name
      "#{category} Fee"
    end

    def default_tax_exempt
      false
    end

    def default_title
      [
        period&.strftime('%y').presence,
        membership_category.to_s.presence,
        category.presence,
        'Fee'
      ].join(' ')
    end

  end
end
