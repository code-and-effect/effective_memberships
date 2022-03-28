require 'test_helper'

class MembershipHistoriesTest < ActiveSupport::TestCase

  test 'membership histories are created and set previous end dates' do
    owner = build_member()
    first_category = owner.membership.category

    assert_equal 1, owner.membership_histories.length

    second_category = EffectiveMemberships.Category.where(title: 'Student').first!

    owner.membership.build_membership_category(category: EffectiveMemberships.Category.where(title: 'Student').first!)
    owner.membership.membership_category(category: first_category).mark_for_destruction
    owner.build_membership_history
    owner.save!

    assert_equal 2, owner.membership_histories.length

    first = owner.membership_histories.first
    last = owner.membership_histories.last

    assert_equal Time.zone.now.to_date, last.start_on
    assert_equal owner.membership.number, last.number

    assert_equal [owner.membership.category.to_s], last.categories
    assert_equal [owner.membership.category.id], last.category_ids

    assert (last.bad_standing == false)
    assert last.end_on.nil?

    assert_equal Time.zone.now.to_date, first.end_on
    assert_equal [first_category.to_s], first.categories
    assert_equal [first_category.id], first.category_ids
  end

  test 'membership categories form assigns categories and category_ids' do
    owner = build_member()

    history = owner.membership_histories.first
    assert history.present?

    assert history.category_ids.present?
    assert history.categories.present?
    assert history.membership_category_ids.present?

    assert_equal history.category_ids, history.membership_category_ids
    assert_equal history.categories.map(&:to_s), history.membership_categories.map(&:to_s)

    categories = EffectiveMemberships.Category.all

    history.update!(membership_category_ids: categories.map(&:id))

    assert_equal history.category_ids, categories.map(&:id)
    assert_equal history.categories, categories.map(&:to_s)
  end

end
