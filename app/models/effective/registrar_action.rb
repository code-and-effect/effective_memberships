module Effective
  class RegistrarAction
    include ActiveModel::Model

    # All Actions
    attr_accessor :current_user
    attr_accessor :current_action
    attr_accessor :user, :user_id, :user_type

    # Bad Standing
    attr_accessor :bad_standing_reason

    # Reclassify
    attr_accessor :membership_category_id
    attr_accessor :skip_fees

    # All Action Validations
    validates :current_action, presence: true
    validates :current_user, presence: true
    validates :user, presence: true

    # Bad Standing
    validates :bad_standing_reason, presence: true, if: -> { current_action == :bad_standing }

    # Reclassification
    validates :membership_category_id, presence: true, if: -> { current_action == :reclassify }

    def to_s
      'action' # Empty string
    end

    def good_standing!
      update!(current_action: :good_standing)
      EffectiveMemberships.Registrar.good_standing!(user)
    end

    def bad_standing!
      update!(current_action: :bad_standing)
      EffectiveMemberships.Registrar.bad_standing!(user, reason: bad_standing_reason)
    end

    def reclassify!
      update!(current_action: :reclassify)
      EffectiveMemberships.Registrar.reclassify!(user, to: membership_category, skip_fees: skip_fees?)
    end

    def update!(atts)
      assign_attributes(atts); save!
    end

    def save!
      valid? ? true : raise('invalid')
    end

    def user
      @user ||= (@user_type.constantize.find(@user_id) if @user_type && @user_id)
    end

    def user_type
      @user_type || (@user.class.name if @user)
    end

    def user_id
      @user_id || (@user.id if @user)
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
