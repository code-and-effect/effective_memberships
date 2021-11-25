require 'test_helper'

class MembershipHistoriesTest < ActiveSupport::TestCase

  test 'membership histories are created and set previous end dates' do
    user = build_member()
    binding.pry

    assert_equal 1, user.membership_histories.length

    user.membership.category = EffectiveMemberships.MembershipCategory.where(title: 'Student').first!
    user.build_membership_history
    user.save!

    assert_equal 2, user.membership_histories.length


    # history = rpbio.registrant_histories.last

    # assert_equal Time.zone.now.to_date, history.start_on
    # assert_equal rpbio.number, history.number
    # assert_equal rpbio.registrant_category, history.registrant_category
    # assert history.on_leave?
    # assert history.end_on.blank?

    # # Return from leave
    # Register.reinstate!(rpbio, to: rpbio.registrant_category)
    # assert_equal 3, rpbio.registrant_histories.length

    # history.reload
    # assert_equal Time.zone.now.to_date, history.end_on

    # history2 = rpbio.registrant_histories.last
    # refute history2.on_leave?
    # assert history2.end_on.blank?
  end
end
