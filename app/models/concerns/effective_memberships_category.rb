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
  end

  included do
    log_changes if respond_to?(:log_changes)

    # rich_text_body - Used by the select step
    has_many_rich_texts

    effective_resource do
      title                 :string
      position              :integer

      # Applicants
      can_apply_new             :boolean
      can_apply_existing        :boolean
      can_apply_restricted      :boolean
      can_apply_restricted_ids  :text

      applicant_fee              :integer
      applicant_wizard_steps     :text

      min_applicant_educations          :integer
      min_applicant_experiences_months  :integer
      min_applicant_references          :integer
      min_applicant_courses             :integer
      min_applicant_files               :integer

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

      # Renewals
      can_renew             :boolean

      annual_fee            :integer
      renewal_fee           :integer

      timestamps
    end

    serialize :can_apply_restricted_ids, Array
    serialize :applicant_wizard_steps, Array

    scope :deep, -> { includes(:rich_texts) }
    scope :sorted, -> { order(:position) }

    scope :can_apply, -> {
      where(can_apply_new: true)
      .or(where(can_apply_existing: true))
      .or(where(can_apply_restricted: true))
    }

    scope :for_applicant, -> { deep.sorted.can_apply }

    validates :title, presence: true, uniqueness: true
    validates :position, presence: true

    after_initialize(if: -> { new_record? }) do
      self.applicant_wizard_steps = EffectiveMemberships.Applicant.all_wizard_steps
    end

    before_validation do
      self.position ||= (self.class.pluck(:position).compact.max || -1) + 1
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
    end
  end

  # Instance Methods

  def to_s
    title.presence || 'New Membership Category'
  end

  def applicant_qb_item_name
    'QuickBooks'
  end

  def applicant_tax_exempt
    false
  end

  def can_apply?
    can_apply_new? || can_apply_existing? || can_apply_restricted?
  end

  def can_apply_restricted_ids
    Array(self[:can_apply_restricted_ids]) - [nil, '']
  end

  def applicant_wizard_steps
    Array(self[:applicant_wizard_steps]).map(&:to_sym) - [nil, '']
  end

  def applicant_wizard_steps_collection
    wizard_steps = EffectiveMemberships.Applicant.const_get(:WIZARD_STEPS)
    required_steps = EffectiveMemberships.Applicant.required_wizard_steps

    wizard_steps.map do |step, title|
      [title, step, 'disabled' => required_steps.include?(step)]
    end
  end

end
