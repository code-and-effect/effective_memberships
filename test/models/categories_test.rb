require 'test_helper'

class CategoriesTest < ActiveSupport::TestCase

  test 'build_category is valid' do
    assert build_category().valid?
  end

  test 'new membership category defaults to all wizard steps' do
    category = build_category()
    assert_equal Effective::Applicant::WIZARD_STEPS.keys, category.applicant_wizard_steps
  end

end