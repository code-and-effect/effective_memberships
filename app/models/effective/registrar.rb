module Effective
  class Registrar

    def renewal_fee_date(date:)
      Date.new(date.year, 12, 1) # Fees roll over every December 1st
    end

    def late_fee_date(period:)
      Date.new(period.year, 2, 1) # Fees are late after February 1st
    end

    def bad_standing_date(period:)
      Date.new(period.year, 3, 1) # Membership in bad standing after March 1st
    end

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
      fee = user.build_prorated_fee(date: date)
      raise('already has purchased prorated fee') if fee.purchased?

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
      period(date: Time.zone.now)
    end

    # Returns a date of Jan 1, Year
    def period(date:)
      cutoff = renewal_fee_date(date: date) # period_end_on
      (date < cutoff) ? date.beginning_of_year : date.advance(years: 1).beginning_of_year
    end

    # This is intended to be run once per day in a rake task
    # Create Renewal and Late fees
    def create_fees!(period: nil, late_on: nil, bad_standing_on: nil)
      # The current period, based on Time.zone.now
      period ||= current_period
      late_on ||= late_fee_date(period: period)
      bad_standing_on ||= bad_standing_date(period: period)

      # Create Renewal Fees
      Effective::Membership.create_renewal_fees(period).find_each do |membership|
        fee = membership.user.build_renewal_fee(period: period, late_on: late_on, bad_standing_on: bad_standing_on)
        raise("expected build_renewal_fee to return a fee for period #{period}") unless fee.kind_of?(Effective::Fee)
        next if fee.purchased?

        fee.save!
      end

      # Create Late Fees
      Effective::Membership.create_late_fees(period).find_each do |membership|
        fee = membership.user.build_late_fee(period: period)
        next if fee.blank? || fee.purchased?

        fee.save!
      end

      # Update Membership Status - Assign In Bad Standing
      Effective::Membership.deep.with_unpaid_fees_through(period).find_each do |membership|
        membership.user.update_membership_status!
      end

      true
    end

    def fee_payment_purchased!(user)
      raise('expecting a memberships user') unless user.class.respond_to?(:effective_memberships_user?)
      user.update_membership_status!
    end

    protected

    def save!(user, date: Time.zone.now)
      user.build_membership_history(start_on: date)
      user.save!
    end

  end
end
