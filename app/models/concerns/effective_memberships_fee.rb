# EffectiveMembershipsFee
#
# Mark your user model with effective_memberships_fee to get all the includes

module EffectiveMembershipsFee
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_fee
      include ::EffectiveMembershipsFee
    end
  end

  module ClassMethods
    def effective_memberships_fee?; true; end

    def categories
      ['Applicant', 'Prorated', 'Renewal', 'Late', 'Other']
    end

  end

  included do
    acts_as_purchasable
    log_changes(to: :user) if respond_to?(:log_changes)

    # Every fee is charged to a user
    belongs_to :user, polymorphic: true

    # This fee may belong to an application or other parent model
    belongs_to :parent, polymorphic: true, optional: true

    # The membership category for this fee
    belongs_to :membership_category, optional: true

    effective_resource do
      title         :string
      category      :string

      period        :date
      due_at        :datetime

      price         :integer
      qb_item_name  :string
      tax_exempt    :boolean

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:user, :parent, :membership_category) }

    before_validation do
      self.title ||= build_title()
      self.qb_item_name ||= build_qb_item_name()
      self.tax_exempt ||= build_tax_exempt()
    end

    validates :title, presence: true
    validates :category, presence: true

    # validates :period, presence: true
    # validates :due_at, presence: true

    validates :price, presence: true
    validates :qb_item_name, presence: true

    validate(if: -> { category.present? }) do
      self.errors.add(:category, 'is invalid') unless self.class.categories.include?(category)
    end
  end

  def to_s
    title.presence || 'New Fee'
  end

  # Used by applicant.applicant_submit_fees
  def applicant_submit_fee?
    category == 'Applicant'
  end

  def fee_payment_fee?
    category != 'Applicant'
  end

  private

  def build_title
    "#{category} Fee" if category.present?
  end

  def build_qb_item_name
    "#{category} Fee" if category.present?
  end

  def build_tax_exempt
    false
  end

end
