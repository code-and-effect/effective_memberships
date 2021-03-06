# frozen_string_literal: true

# EffectiveMembershipsCategory
#
# Mark your category model with effective_memberships_category to get all the includes

module EffectiveMembershipsCategory
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_category
      include ::EffectiveMembershipsCategory
    end
  end

  module ClassMethods
    def effective_memberships_category?; true; end

    def category_types
      ['Individual', 'Organization']
    end

    def categories
      []
    end
  end

  included do
    log_changes(except: :memberships) if respond_to?(:log_changes)

    # rich_text_body - Used by the select step
    has_many_rich_texts

    # rich_text_applicant_all_steps_content
    # rich_text_applicant_start_content
    # rich_text_applicant_select_content
    # rich_text_applicant_select_content

    has_many :membership_categories, class_name: 'Effective::MembershipCategory', as: :category

    effective_resource do
      category_type         :string

      title                 :string
      category              :string
      position              :integer

      # Applicants
      can_apply_new             :boolean
      can_apply_existing        :boolean
      can_apply_restricted      :boolean
      can_apply_restricted_ids  :text

      applicant_fee              :integer
      applicant_wizard_steps     :text

      min_applicant_educations          :integer
      min_applicant_endorsements        :integer
      min_applicant_equivalences        :integer
      min_applicant_experiences_months  :integer
      min_applicant_references          :integer
      min_applicant_courses             :integer
      min_applicant_files               :integer

      # Applicant Reviews
      min_applicant_reviews             :integer
      applicant_review_wizard_steps     :text

      # Prorated Fees
      prorated_jan        :integer
      prorated_feb        :integer
      prorated_mar        :integer
      prorated_apr        :integer
      prorated_may        :integer
      prorated_jun        :integer
      prorated_jul        :integer
      prorated_aug        :integer
      prorated_sep        :integer
      prorated_oct        :integer
      prorated_nov        :integer
      prorated_dec        :integer

      # Fee Payments
      fee_payment_wizard_steps   :text

      # Renewals
      create_renewal_fees   :boolean
      renewal_fee           :integer

      create_late_fees      :boolean
      late_fee              :integer

      create_bad_standing  :boolean

      # Pricing
      qb_item_name          :string
      tax_exempt            :boolean

      timestamps
    end

    serialize :can_apply_restricted_ids, Array
    serialize :applicant_wizard_steps, Array
    serialize :applicant_review_wizard_steps, Array
    serialize :fee_payment_wizard_steps, Array

    scope :deep, -> { includes(:rich_texts) }
    scope :sorted, -> { order(:position) }

    scope :can_apply, -> {
      where(can_apply_new: true)
      .or(where(can_apply_existing: true))
      .or(where(can_apply_restricted: true))
    }

    validates :title, presence: true, uniqueness: true
    validates :category_type, presence: true
    validates :position, presence: true

    before_validation do
      self.applicant_wizard_steps = EffectiveMemberships.Applicant.all_wizard_steps if applicant_wizard_steps.blank?
      self.applicant_review_wizard_steps = EffectiveMemberships.ApplicantReview.all_wizard_steps if applicant_review_wizard_steps.blank?
      self.fee_payment_wizard_steps = EffectiveMemberships.FeePayment.all_wizard_steps if fee_payment_wizard_steps.blank?
    end

    before_validation do
      self.position ||= (self.class.pluck(:position).compact.max || -1) + 1
      self.category_type ||= self.class.category_types.first
    end

    with_options(if: -> { can_apply? }) do
      validates :can_apply_restricted_ids, presence: true, if: -> { can_apply_restricted? }

      validates :applicant_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_jan, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_feb, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_mar, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_apr, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_may, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_jun, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_jul, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_aug, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_sep, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_oct, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_nov, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :prorated_dec, presence: true, numericality: { greater_than_or_equal_to: 0 }

      validates :qb_item_name, presence: true
      validates :tax_exempt, inclusion: { in: [true, false] }
    end
  end

  # Instance Methods

  def to_s
    title.presence || 'New Membership Category'
  end

  def can_apply?
    can_apply_new? || can_apply_existing? || can_apply_restricted?
  end

  def individual?
    category_type == 'Individual'
  end

  def organization?
    category_type == 'Organization'
  end

  def prorated_fee(date:)
    send("prorated_#{date.strftime('%b').downcase}").to_i
  end

  def discount_fee(date:)
    0 - prorated_fee(date: date)
  end

  def can_apply_restricted_ids
    Array(self[:can_apply_restricted_ids]) - [nil, '']
  end

  def optional_applicant_wizard_steps
    applicant_wizard_steps - EffectiveMemberships.Applicant.required_wizard_steps
  end

  def optional_fee_payment_wizard_steps
    fee_payment_wizard_steps - EffectiveMemberships.FeePayment.required_wizard_steps
  end

  def optional_applicant_review_wizard_steps
    applicant_review_wizard_steps - EffectiveMemberships.ApplicantReview.required_wizard_steps
  end

  def applicant_wizard_steps
    (Array(self[:applicant_wizard_steps]) - [nil, '']).map(&:to_sym)
  end

  def fee_payment_wizard_steps
    (Array(self[:fee_payment_wizard_steps]) - [nil, '']).map(&:to_sym)
  end

  def applicant_review_wizard_steps
    (Array(self[:applicant_review_wizard_steps]) - [nil, '']).map(&:to_sym)
  end

  def applicant_wizard_steps_collection
    wizard_steps = EffectiveMemberships.Applicant.wizard_steps_hash
    required_steps = EffectiveMemberships.Applicant.required_wizard_steps

    wizard_steps.map do |step, title|
      [title, step, 'disabled' => required_steps.include?(step)]
    end
  end

  def fee_payment_wizard_steps_collection
    wizard_steps = EffectiveMemberships.FeePayment.wizard_steps_hash
    required_steps = EffectiveMemberships.FeePayment.required_wizard_steps

    wizard_steps.map do |step, title|
      [title, step, 'disabled' => required_steps.include?(step)]
    end
  end

  def applicant_fee_qb_item_name
    'Applicant'
  end

  def applicant_fee_tax_exempt
    tax_exempt
  end

  def stamp_fee
    0
  end

  def stamp_fee_qb_item_name
    qb_item_name
  end

  def stamp_fee_tax_exempt
    tax_exempt
  end

end
