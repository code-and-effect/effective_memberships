# frozen_string_literal: true

# EffectiveMembershipsFeePayment
#
# Mark your model with effective_memberships_fee_payment to get all the includes

module EffectiveMembershipsFeePayment
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_fee_payment
      include ::EffectiveMembershipsFeePayment
    end
  end

  module ClassMethods
    def effective_memberships_fee_payment?; true; end

    def required_wizard_steps
      [:start, :summary, :billing, :checkout, :submitted]
    end
  end

  included do
    acts_as_purchasable_parent
    acts_as_tokened

    acts_as_statused(
      :draft,       # Just Started
      :submitted    # All Done
    )

    acts_as_wizard(
      start: 'Start',
      demographics: 'Demographics',         # Individual only. Users fields.
      organization: 'Organization',         # Organization only. Organization fields.
      declarations: 'Declarations',
      summary: 'Review',
      billing: 'Billing Address',
      checkout: 'Checkout',
      submitted: 'Submitted'
    )

    acts_as_purchasable_wizard

    log_changes(except: :wizard_steps) if respond_to?(:log_changes)

    # Declarations Step
    attr_accessor :declare_code_of_ethics
    attr_accessor :declare_truth

    # Application Namespace
    belongs_to :user, polymorphic: true
    accepts_nested_attributes_for :user

    belongs_to :organization, polymorphic: true, optional: true
    accepts_nested_attributes_for :organization

    # Like maybe optionally it makes sense.
    belongs_to :category, polymorphic: true, optional: true

    # Effective Namespace
    has_many :fees, -> { order(:id) }, as: :parent, class_name: 'Effective::Fee', dependent: :nullify
    accepts_nested_attributes_for :fees, reject_if: :all_blank, allow_destroy: true

    has_many :orders, -> { order(:id) }, as: :parent, class_name: 'Effective::Order', dependent: :nullify
    accepts_nested_attributes_for :orders

    effective_resource do
      # Acts as Statused
      status                 :string, permitted: false
      status_steps           :text, permitted: false

      # Dates
      period                 :date
      submitted_at           :datetime

      # Acts as Wizard
      wizard_steps           :text, permitted: false

      timestamps
    end

    scope :deep, -> { includes(:user, :organization, :category, :orders) }
    scope :sorted, -> { order(:id) }

    scope :in_progress, -> { where.not(status: [:submitted]) }
    scope :done, -> { where(status: [:submitted]) }

    scope :for, -> (user) {
      raise('expected a effective memberships user') unless user.class.try(:effective_memberships_user?)
      where(user: user).or(where(organization: user.organizations))
    }

    before_validation do
      self.period ||= EffectiveMemberships.Registrar.current_period
    end

    before_validation(if: -> { new_record? || current_step == :start }) do
      self.organization_type = (EffectiveMemberships.Organization.name if organization_id.present?)
    end

    before_validation(if: -> { current_step == :start && user && user.membership }) do
      self.category ||= user.membership.categories.first if user.membership.categories.length == 1
    end

    # All Steps validations
    validates :user, presence: true
    validates :period, presence: true

    # Declarations Step
    with_options(if: -> { current_step == :declarations }) do
      validates :declare_code_of_ethics, acceptance: true
      validates :declare_truth, acceptance: true
    end

    # Clear required steps memoization
    after_save { @_required_steps = nil }

    # This required_steps is defined inside the included do .. end block so it overrides the acts_as_wizard one.
    def required_steps
      return self.class.test_required_steps if Rails.env.test? && self.class.test_required_steps.present?

      @_required_steps ||= begin
        wizard_steps = self.class.all_wizard_steps
        required_steps = self.class.required_wizard_steps

        fee_payment_steps = Array(category&.fee_payment_wizard_steps)

        fee_payment_steps.delete(:organization) unless organization?

        wizard_steps.select do |step|
          required_steps.include?(step) || category.blank? || fee_payment_steps.include?(step)
        end
      end
    end

    # All Fees and Orders
    # Overriding acts_as_purchasable_wizard
    def submit_fees
      fees
    end

    def submit_order
      orders.first
    end

    # We take over the owner's outstanding fees.
    def find_or_build_submit_fees
      Array(owner.outstanding_fee_payment_fees).each { |fee| fees << fee unless fees.include?(fee) }
      submit_fees
    end

    def after_submit_purchased!
      EffectiveMemberships.Registrar.fee_payment_purchased!(owner)
    end

  end

  def to_s
    'Fee Payment'
  end

  def owner
    organization || user
  end

  def owner_symbol
    organization? ? :organization : :user
  end

  def individual?
    !owner.kind_of?(EffectiveMemberships.Organization)
  end

  def organization?
    owner.kind_of?(EffectiveMemberships.Organization)
  end

  # Instance Methods
  def in_progress?
    draft?
  end

  def done?
    submitted?
  end

  def select!
    reset!
  end

  def reset!
    assign_attributes(wizard_steps: wizard_steps.slice(:start))
    save!
  end

end
