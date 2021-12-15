require 'test_helper'

class MembershipHistoriesTest < ActiveSupport::TestCase

  test 'membership histories are created and set previous end dates' do
    owner = build_member()
    first_category = owner.membership.category

    assert_equal 1, owner.membership_histories.length

    owner.membership.category = EffectiveMemberships.Category.where(title: 'Student').first!
    owner.build_membership_history
    owner.save!

    assert_equal 2, owner.membership_histories.length

    first = owner.membership_histories.first
    last = owner.membership_histories.last

    assert_equal Time.zone.now.to_date, last.start_on
    assert_equal owner.membership.number, last.number
    assert_equal owner.membership.category, last.category
    assert (last.bad_standing == false)
    assert last.end_on.nil?

    assert_equal Time.zone.now.to_date, first.end_on
    assert_equal first_category, first.category
  end
end
