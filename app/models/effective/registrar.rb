module Effective
  class Registrar

    include EffectiveMembershipsRegistrar

    def renewal_fee_date(date:)
      Date.new(date.year, 12, 1) # Fees roll over every December 1st
    end

    def late_fee_date(period:)
      Date.new(period.year, 2, 1) # Fees are late after February 1st
    end

    def bad_standing_date(period:)
      Date.new(period.year, 3, 1) # Membership in bad standing after March 1st
    end

  end
end
