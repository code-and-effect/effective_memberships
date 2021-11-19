module Effective
  class Registrar

    def register!(user, to:)
      raise('expecting a memberships user') unless user.class.respond_to?(:effective_memberships_user?)
      raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)

      user.membership_change_date ||= Time.zone.now

      # Build a membership
      membership = user.membership || user.build_membership

      # Assign Category
      membership.category = to

      # Assign Dates
      membership.joined_on ||= user.membership_change_date  # Only if not already present
      membership.registration_on = user.membership_change_date  # Always new registration_on

      # Assign Number
      membership.number = next_membership_number(user, to: to)

      # Save user
      save!(user)
    end

    def next_membership_number(user, to:)
      raise('expecting a memberships user') unless user.class.respond_to?(:effective_memberships_user?)
      raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)
    end

    private

    def save!(user)
      user.build_registrant_history if user.valid?
      user.save!
    end

  end
end
