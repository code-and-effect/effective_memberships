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
      ['Applicant']
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

      price         :integer
      qb_item_name  :string
      tax_exempt    :boolean

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:user, :parent, :membership_category) }

    before_validation do
      self.title ||= build_title()
    end

    validates :title, presence: true
    validates :category, presence: true

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

  private

  def build_title
    return nil if category.blank?
    "#{category} Fee"
  end

end
