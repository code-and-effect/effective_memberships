require 'test_helper'

class MembershipCategoriesTest < ActiveSupport::TestCase

  test 'build_membership_category is valid' do
    assert build_membership_category().valid?
  end

  test 'new membership category defaults to all wizard steps' do
    category = build_membership_category()
    assert_equal Effective::Applicant::WIZARD_STEPS.keys, category.applicant_wizard_steps
  end

end
