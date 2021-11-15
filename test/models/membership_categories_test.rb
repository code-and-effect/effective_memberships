require 'test_helper'

class MembershipCategoriesTest < ActiveSupport::TestCase

  test 'build_membership_category is valid' do
    assert build_membership_category().valid?
  end

end
