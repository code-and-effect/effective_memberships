require 'test_helper'

class MembershipTest < ActiveSupport::TestCase

  test 'number_as_integer is assigned' do
    owner = build_member()
    membership = owner.membership

    assert membership.number.present?
    assert membership.number_as_integer.present?

    membership.update!(number: 'asdf')
    assert_equal 'asdf', membership.number
    assert membership.number_as_integer.nil?

    membership.update!(number: '123')
    assert_equal '123', membership.number
    assert_equal 123, membership.number_as_integer
  end

end
