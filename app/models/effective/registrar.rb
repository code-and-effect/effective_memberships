module Effective
  class Registrar

    def register!(user, to:, date: nil, number: nil)
      raise('expecting a memberships user') unless user.class.respond_to?(:effective_memberships_user?)
      raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)

      # Default Date and next number
      date ||= Time.zone.now
      number = next_membership_number(user, to: to) if number.blank?

      # Build a membership
      membership = user.membership || user.build_membership

      # Assign Category
      membership.category = to

      # Assign Dates
      membership.joined_on ||= date  # Only if not already present
      membership.registration_on = date  # Always new registration_on

      # Assign Number
      membership.number = number

      # Save user
      save!(user, date: date)
    end

    def next_membership_number(user, to:)
      raise('expecting a memberships user') unless user.class.respond_to?(:effective_memberships_user?)
      raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)

      # Just a simple number right now
      Effective::Membership.all.max_number + 1
    end

    private

    def save!(user, date: Time.zone.now)
      user.build_membership_history(start_on: date)
      user.save!
    end

  end
end
