# Form Object for the Admin Change Status screens

module Effective
  class RegistrarAction
    include ActiveModel::Model

    # All Actions
    attr_accessor :current_user
    attr_accessor :current_action
    attr_accessor :owner, :owner_id, :owner_type

    # Bad Standing
    attr_accessor :bad_standing_reason

    # Reclassify & Register
    attr_accessor :membership_category_id
    attr_accessor :membership_number
    attr_accessor :skip_fees

    # All Action Validations
    validates :current_action, presence: true
    validates :current_user, presence: true
    validates :owner, presence: true

    # Bad Standing
    validates :bad_standing_reason, presence: true, if: -> { current_action == :bad_standing }

    # Reclassification & Register
    validates :membership_category_id, presence: true,
      if: -> { current_action == :reclassify || current_action == :register }

    def to_s
      'action'
    end

    def good_standing!
      update!(current_action: :good_standing)
      EffectiveMemberships.Registrar.good_standing!(owner)
    end

    def bad_standing!
      update!(current_action: :bad_standing)
      EffectiveMemberships.Registrar.bad_standing!(owner, reason: bad_standing_reason)
    end

    def reclassify!
      update!(current_action: :reclassify)
      EffectiveMemberships.Registrar.reclassify!(owner, to: membership_category, skip_fees: skip_fees?)
    end

    def fees_paid!
      update!(current_action: :fees_paid)
      EffectiveMemberships.Registrar.fees_paid!(owner)
    end

    def remove!
      update!(current_action: :remove)
      EffectiveMemberships.Registrar.remove!(owner)
    end

    def register!
      update!(current_action: :register)
      EffectiveMemberships.Registrar.register!(owner, to: membership_category, number: membership_number.presence, skip_fees: skip_fees?)
    end

    def update!(atts)
      assign_attributes(atts); save!
    end

    def save!
      valid? ? true : raise('invalid')
    end

    def owner
      @owner ||= (@owner_type.constantize.find(@owner_id) if @owner_type && @owner_id)
    end

    def owner_type
      @owner_type || (@owner.class.name if @owner)
    end

    def owner_id
      @owner_id || (@owner.id if @owner)
    end

    private

    def membership_category
      EffectiveMemberships.MembershipCategory.find(@membership_category_id) if @membership_category_id
    end

    def skip_fees?
      EffectiveResources.truthy?(@skip_fees)
    end

  end
end
