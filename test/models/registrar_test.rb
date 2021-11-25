require 'test_helper'

class RegistrarTest < ActiveSupport::TestCase
  test 'register member' do
    user = build_user()
    category = EffectiveMemberships.MembershipCategory.first

    EffectiveMemberships.Registrar.register!(user, to: category)

    assert_equal 1, user.fees.length
  end

end
