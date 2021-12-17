require 'test_helper'

class RegistrarAssignTest < ActiveSupport::TestCase
  test 'assign new user' do
    owner = build_user()
    category1 = EffectiveMemberships.Category.first
    category2 = EffectiveMemberships.Category.last
    refute_equal category1, category2

    refute owner.membership.present?
    assert_equal 0, owner.fees.length

    categories = [category1, category2]
    next_number = EffectiveMemberships.Registrar.next_membership_number(owner, to: categories)

    assert EffectiveMemberships.Registrar.assign!(owner, categories: categories)

    assert owner.membership.present?
    assert_equal next_number, owner.membership.number

    assert_equal 0, owner.fees.length

    assert_equal 2, owner.membership.categories.length
    assert_equal categories, owner.membership.categories
  end

  test 'remove category' do
    owner = build_member()
    assert_equal 1, owner.membership.categories.length

    category1 = owner.membership.category
    category2 = EffectiveMemberships.Category.where.not(id: category1.id).first!

    assert EffectiveMemberships.Registrar.assign!(owner, categories: [category1, category2])
    assert_equal 2, owner.membership.categories.length
    assert_equal [category1, category2], owner.membership.categories

    assert EffectiveMemberships.Registrar.assign!(owner, categories: category2)
    assert_equal 1, owner.membership.categories.length
    assert_equal category2, owner.membership.category
  end

  test 'indemotent changes' do
    owner = build_user()
    category1 = EffectiveMemberships.Category.first
    category2 = EffectiveMemberships.Category.last
    refute_equal category1, category2

    assert owner.membership.blank?

    assert EffectiveMemberships.Registrar.assign!(owner, categories: [category1, category2])
    assert_equal 1, owner.membership_histories.length

    # Do the same. Should be no changes to history
    assert EffectiveMemberships.Registrar.assign!(owner, categories: [category1, category2])
    assert_equal 1, owner.membership_histories.length

    # Change history
    assert EffectiveMemberships.Registrar.assign!(owner, categories: category1)
    assert_equal 2, owner.membership_histories.length

    # Change history
    assert EffectiveMemberships.Registrar.assign!(owner, categories: category2)
    assert_equal 3, owner.membership_histories.length
  end

end
