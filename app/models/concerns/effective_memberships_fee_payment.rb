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

    def all_wizard_steps
      const_get(:WIZARD_STEPS).keys
    end

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
      demographics: 'Demographics',
      declarations: 'Declarations',
      summary: 'Review',
      billing: 'Billing Address',
      checkout: 'Checkout',
      submitted: 'Submitted'
    )

    log_changes(except: :wizard_steps) if respond_to?(:log_changes)

    # Declarations Step
    attr_accessor :declare_code_of_ethics
    attr_accessor :declare_truth

    # Throwaway
    attr_accessor :upgrade, :downgrade

    # Application Namespace
    belongs_to :owner, polymorphic: true
    accepts_nested_attributes_for :owner

    belongs_to :user, polymorphic: true, optional: true
    accepts_nested_attributes_for :user

    # Like maybe optionally it makes sense.
    belongs_to :category, polymorphic: true, optional: true

    has_many :fees, -> { order(:id) }, as: :parent, class_name: 'Effective::Fee', dependent: :nullify
    accepts_nested_attributes_for :fees, reject_if: :all_blank, allow_destroy: true

    # Effective Namespace
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

    scope :deep, -> { includes(:owner, :category, :orders) }
    scope :sorted, -> { order(:id) }

    scope :in_progress, -> { where.not(status: [:submitted]) }
    scope :done, -> { where(status: [:submitted]) }

    before_validation do
      self.period ||= EffectiveMemberships.Registrar.current_period
    end

    before_validation(if: -> { current_step == :start && owner && owner.membership }) do
      self.category ||= owner.membership.categories.first if owner.membership.categories.length == 1
    end

    validates :period, presence: true

    # All Steps validations
    validates :owner, presence: true

    # Declarations Step
    with_options(if: -> { current_step == :declarations }) do
      validates :declare_code_of_ethics, acceptance: true
      validates :declare_truth, acceptance: true
    end

    # Billing Step
    validate(if: -> { current_step == :billing && owner.present? }) do
      self.errors.add(:base, "must have a billing address") unless owner.billing_address.present?
      self.errors.add(:base, "must have an email") unless owner.email.present?
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

        wizard_steps.select do |step|
          required_steps.include?(step) || category.blank? || fee_payment_steps.include?(step)
        end
      end
    end

    after_purchase do |_order|
      raise('expected submit_order to be purchased') unless submit_order&.purchased?

      submit_purchased!
      after_submit_purchased!
      EffectiveMemberships.Registrar.fee_payment_purchased!(owner)
    end
  end

  def to_s
    'Fee Payment'
  end

  # Instance Methods
  def in_progress?
    draft?
  end

  def done?
    submitted?
  end

  def can_visit_step?(step)
    can_revisit_completed_steps(step)
  end

  def outstanding_fees
    owner&.outstanding_fee_payment_fees
  end

  def select!
    reset!
  end

  def reset!
    assign_attributes(wizard_steps: wizard_steps.slice(:start))
    save!
  end

  # Work with effective_organizations
  def organization!
    if upgrade_individual_to_organization?
      save!
      update!(owner: owner.representatives.first.organization)
    elsif downgrade_organization_to_individual?
      save!
      update!(owner: current_user)
    else
      save!
    end
  end

  def upgrade_individual_to_organization?
    return false unless EffectiveResources.truthy?(upgrade)
    return false unless owner.class.respond_to?(:effective_organizations_user?)
    owner.representatives.any?(&:new_record?)
  end

  def downgrade_organization_to_individual?
    return false unless EffectiveResources.truthy?(downgrade)
    return false unless owner.class.respond_to?(:effective_organizations_organization?)
    return false if current_user.blank?
    owner.representatives.any?(&:marked_for_destruction?)
  end

  # All Fees and Orders
  def submit_fees
    fees
  end

  def submit_order
    orders.first
  end

  # We take over the owner's outstanding fees.
  def find_or_build_submit_fees
    Array(outstanding_fees).each { |fee| fees << fee unless fees.include?(fee) }
    submit_fees
  end

  def find_or_build_submit_order
    order = submit_order || orders.build(user: owner)
    fees = submit_fees()

    fees.each do |fee|
      order.add(fee) unless order.purchasables.include?(fee)
    end

    order.purchasables.each do |purchasable|
      order.remove(purchasable) unless fees.include?(purchasable)
    end

    order.billing_address = owner.billing_address if owner.billing_address.present?

    order.save

    order
  end

  # Should be indempotent.
  def build_submit_fees_and_order
    return false if was_submitted?

    fees = find_or_build_submit_fees()
    raise('already has purchased submit fees') if fees.any? { |fee| fee.purchased? }

    order = find_or_build_submit_order()
    raise('already has purchased submit order') if order.purchased?

    true
  end

  # Owner clicks on the Billing Submit. Next step is Checkout
  def billing!
    ready!
  end

  def ready!
    build_submit_fees_and_order
    save!
  end

  # Called automatically via after_purchase hook above
  def submit_purchased!
    return false if was_submitted?

    wizard_steps[:checkout] = Time.zone.now
    submit!
  end

  # A hook to extend
  def after_submit_purchased!
  end

  # Draft -> Submitted
  def submit!
    raise('already submitted') if was_submitted?
    raise('expected a purchased order') unless submit_order&.purchased?

    wizard_steps[:checkout] ||= Time.zone.now
    wizard_steps[:submitted] = Time.zone.now
    submitted!
  end

end
