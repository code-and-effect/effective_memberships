module Effective
  class MembershipCategory < ActiveRecord::Base
    belongs_to :category, polymorphic: true
    belongs_to :membership, polymorphic: true

    def to_s
      'membership category'
    end

  end
end
