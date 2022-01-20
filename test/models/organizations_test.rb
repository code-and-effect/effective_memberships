require 'test_helper'

class OrganizationsTest < ActiveSupport::TestCase
  test 'organization' do
    organization = build_organization()
    assert organization.valid?
  end

  test 'organization member' do
    organization = build_member(type: :organization)
    assert organization.valid?

    assert organization.membership.present?
    assert organization.membership_present?
  end

  test 'add user to member organization' do
    user = build_user()
    user.save!
    refute user.membership_present?
    refute user.is?(:member)

    organization = build_member(type: :organization)
    organization.save!
    assert organization.membership_present?
    assert organization.is?(:member)

    organization.representatives.build(user: user)
    organization.save!

    assert user.membership_present?
    assert user.is?(:member)
  end

  test 'add user to member organization another way' do
    user = build_user()
    user.save!
    refute user.membership_present?
    refute user.is?(:member)

    organization = build_member(type: :organization)
    organization.save!
    assert organization.membership_present?
    assert organization.is?(:member)

    Effective::Representative.create!(user: user, organization: organization)

    assert user.membership_present?
    assert user.is?(:member)
  end

  test 'remove user from member organization' do
    user = build_user()
    organization = build_member(type: :organization)
    organization.representatives.build(user: user)
    organization.save!

    assert user.membership.blank?
    assert user.membership_present?
    assert user.is?(:member)

    assert organization.membership.present?
    assert organization.membership_present?
    assert organization.is?(:member)

    # Now remove
    organization.representatives.first.destroy!

    user.reload
    refute user.membership_present?
    refute user.is?(:member)
  end

  test 'member role added to user when organization registered' do
    category = EffectiveMemberships.Category.first

    user = build_user()
    organization = build_organization()
    organization.representatives.build(user: user)
    organization.save!

    refute user.is?(:member)
    refute organization.is?(:member)

    assert EffectiveMemberships.Registrar.register!(organization, to: category)

    assert organization.is?(:member)
    assert user.is?(:member)
  end

  test 'member role added to user when organization assigned' do
    category = EffectiveMemberships.Category.first

    user = build_user()
    organization = build_organization()
    organization.representatives.build(user: user)
    organization.save!

    refute user.is?(:member)
    refute organization.is?(:member)

    assert EffectiveMemberships.Registrar.assign!(organization, categories: category)

    assert organization.is?(:member)
    assert user.is?(:member)
  end

  test 'member role removed from user when organization membership removed' do
    user = build_user()
    organization = build_member(type: :organization)
    organization.representatives.build(user: user)
    organization.save!

    assert user.membership.blank?
    assert user.is?(:member)

    assert organization.membership.present?
    assert organization.membership_present?
    assert organization.is?(:member)

    assert EffectiveMemberships.Registrar.remove!(organization)

    refute organization.is?(:member)
    refute user.is?(:member)

  end

end
