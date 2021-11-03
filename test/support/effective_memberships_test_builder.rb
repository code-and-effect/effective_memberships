module EffectiveMembershipsTestBuilder

  def build_membership_category
    MembershipCategory.new(
      title: 'Category A',
      can_apply: true,
      applicant_fee: 100_00,
      annual_fee: 250_00
    )
  end

  def create_user!
    build_user.tap { |user| user.save! }
  end

  def build_user
    @user_index ||= 0
    @user_index += 1

    User.new(
      email: "user#{@user_index}@example.com",
      password: 'rubicon2020',
      password_confirmation: 'rubicon2020',
      first_name: 'Test',
      last_name: 'User'
    )
  end

end
