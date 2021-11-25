require 'test_helper'

class MembershipUsersTest < ActiveSupport::TestCase

  test 'build_user is valid' do
    assert build_user().valid?
  end

end
