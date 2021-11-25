require 'test_helper'

class RegistrarCreateFeesTest < ActiveSupport::TestCase
  test 'register member' do
    3.times { build_member().save! }

    period = EffectiveMemberships.Registrar.current_period

    assert_equal 3, User.members.all.count
    assert_equal 3, Effective::Membership.all.count

    assert_equal 3, Effective::Membership.create_renewal_fees.all.count
    assert_equal 3, Effective::Membership.create_renewal_fees(period).all.count

  end

end
