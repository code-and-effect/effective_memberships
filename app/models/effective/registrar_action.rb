module Effective
  class RegistrarAction
    include ActiveModel::Model

    # All Actions
    attr_accessor :current_user
    attr_accessor :current_action
    attr_accessor :user, :user_id, :user_type

    # Bad Standing
    attr_accessor :bad_standing_reason

    # All Action Validations
    validates :current_user, presence: true
    validates :user, presence: true

    # Bad Standing
    validates :bad_standing_reason, presence: true, if: -> { current_action == :bad_standing }

    def to_s
      'registrant action'
    end

    def good_standing!
      update!(current_action: :good_standing)
      EffectiveMemberships.Registrar.good_standing!(user)
    end

    def bad_standing!
      update!(current_action: :bad_standing)
      EffectiveMemberships.Registrar.bad_standing!(user, reason: bad_standing_reason)
    end

    def save!
      valid? ? true : raise('invalid')
    end

    def update!(atts)
      assign_attributes(atts); save!
    end

    def user
      @user || (@user_type.constantize.find(@user_id) if @user_type && @user_id)
    end

    def user_type
      @user_type || @user&.class&.name
    end

    def user_id
      @user_id || @user&.id
    end

  end
end
