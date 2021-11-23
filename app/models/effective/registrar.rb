module Effective
  class Registrar

    def register!(user, to:, date: nil, number: nil)
      raise('expecting a memberships user') unless user.class.respond_to?(:effective_memberships_user?)
      raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)
      raise('user has existing membership. use reclassify! instead.') if user.membership.present?

      # Default Date and next number
      date ||= Time.zone.now
      number = next_membership_number(user, to: to) if number.blank?

      # Build a membership
      membership = user.build_membership

      # Assign Category
      membership.category = to

      # Assign Dates
      membership.joined_on ||= date  # Only if not already present
      membership.registration_on = date  # Always new registration_on

      # Assign Number
      membership.number = number

      # Build Fees
      user.build_prorated_fees(date: date)

      # Save user
      save!(user, date: date)
    end

    def next_membership_number(user, to:)
      raise('expecting a memberships user') unless user.class.respond_to?(:effective_memberships_user?)
      raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)

      # Just a simple number right now
      Effective::Membership.all.max_number + 1
    end

    def current_period
      period_on(date: Time.zone.now)
    end

    def period(date:)
      cutoff = period_cutoff_date(date: date)
      (date < cutoff) ? date.beginning_of_year : date.advance(years: 1).beginning_of_year
    end

    def period_cutoff_date(date:)
      year = date.year
      Time.zone.local(year, 10, 1) # Fees are for next year after October 1st
    end

    protected

    def save!(user, date: Time.zone.now)
      user.build_membership_history(start_on: date)
      user.save!
    end

  end
end
