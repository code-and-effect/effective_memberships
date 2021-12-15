module Effective
  class Fee < ActiveRecord::Base
    acts_as_purchasable

    log_changes(to: :owner) if respond_to?(:log_changes)

    # Every fee is charged to a owner
    belongs_to :owner, polymorphic: true

    # This fee may belong to an application or other parent model
    belongs_to :parent, polymorphic: true, optional: true

    # The membership category for this fee, if there's only 1 membership.categories
    belongs_to :category, polymorphic: true, optional: true

    effective_resource do
      fee_type      :string

      title         :string

      period        :date

      late_on           :date
      bad_standing_on   :date

      price             :integer
      qb_item_name      :string
      tax_exempt        :boolean

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:owner, :parent, :category) }

    before_validation(if: -> { owner.present? }) do
      additional = owner.additional_fee_attributes(self)
      raise('expected a Hash of attributes') unless additional.kind_of?(Hash)
      assign_attributes(additional)
    end

    before_validation(if: -> { owner && owner.membership }) do
      self.category ||= owner.membership.categories.first if owner.membership.categories.length == 1
    end

    before_validation do
      self.period ||= default_period()
      self.late_on ||= default_late_on()
      self.bad_standing_on ||= default_bad_standing_on()

      self.qb_item_name ||= default_qb_item_name()
      self.tax_exempt = default_tax_exempt() if tax_exempt.nil?

      self.title ||= default_title()
    end

    validates :fee_type, presence: true
    validates :price, presence: true

    validates :title, presence: true
    validates :period, presence: true
    validates :qb_item_name, presence: true

    validate(if: -> { fee_type.present? }) do
      self.errors.add(:fee_type, 'is not included') unless EffectiveMemberships.fee_types.include?(fee_type)
    end

    with_options(if: -> { fee_type == 'Renewal' }) do
      validates :late_on, presence: true
      validates :bad_standing_on, presence: true
    end

    def to_s
      title.presence || default_title()
    end

    def late?
      return false if late_on.blank?
      return false if purchased?

      late_on <= Time.zone.now.to_date
    end

    def bad_standing?
      return false if bad_standing_on.blank?
      return false if purchased?

      bad_standing_on <= Time.zone.now.to_date
    end

    # Used by applicant.applicant_submit_fees
    def applicant_submit_fee?
      fee_type == 'Applicant'
    end

    def fee_payment_fee?
      fee_type != 'Applicant'
    end

    # Will advance a membership.fees_paid_through_year value when purchased
    def membership_period_fee?
      fee_type == 'Prorated' || fee_type == 'Renewal'
    end

    def custom_fee?
      EffectiveMemberships.custom_fee_types.include?(fee_type)
    end

    private

    def default_period
      EffectiveMemberships.Registrar.current_period
    end

    def default_late_on
      nil
    end

    def default_bad_standing_on
      nil
    end

    def default_title
      [
        period&.strftime('%Y').presence,
        category.to_s.presence,
        fee_type.presence,
        'Fee'
      ].join(' ')
    end

    def default_qb_item_name
      "#{fee_type} Fee"
    end

    def default_tax_exempt
      false
    end

  end
end
