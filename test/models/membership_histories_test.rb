require 'test_helper'

class MembershipHistoriesTest < ActiveSupport::TestCase

  test 'membership histories are created and set previous end dates' do
    user = build_member()
    first_category = user.membership.category

    assert_equal 1, user.membership_histories.length

    user.membership.category = EffectiveMemberships.MembershipCategory.where(title: 'Student').first!
    user.build_membership_history
    user.save!

    assert_equal 2, user.membership_histories.length

    first = user.membership_histories.first
    last = user.membership_histories.last

    assert_equal Time.zone.now.to_date, last.start_on
    assert_equal user.membership.number, last.number
    assert_equal user.membership.category, last.membership_category
    assert (last.in_bad_standing == false)
    assert last.end_on.nil?

    assert_equal Time.zone.now.to_date, first.end_on
    assert_equal first_category, first.membership_category
  end
end
