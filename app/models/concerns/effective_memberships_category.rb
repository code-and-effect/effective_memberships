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

      can_apply             :boolean
      can_renew             :boolean

      applicant_fee         :integer
      annual_fee            :integer
      renewal_fee           :integer

      timestamps
    end

    scope :deep, -> { includes(:rich_texts) }
    scope :sorted, -> { order(:position) }
    scope :can_apply, -> { where(can_apply: true) }

    scope :for_applicant, -> { deep.sorted.can_apply }

    validates :title, presence: true, uniqueness: true
    validates :position, presence: true

    before_validation do
      self.position ||= (self.class.pluck(:position).compact.max || -1) + 1
    end
  end

  # Instance Methods

  def to_s
    title.presence || 'New Membership Category'
  end

end
