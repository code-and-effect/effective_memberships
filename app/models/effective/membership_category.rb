module Effective
  class MembershipCategory < ActiveRecord::Base
    belongs_to :category, polymorphic: true
    belongs_to :membership, polymorphic: true

    log_changes(to: :membership)

    def to_s
      category&.to_s || 'membership category'
    end

  end
end
