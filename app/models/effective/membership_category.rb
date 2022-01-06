module Effective
  class MembershipCategory < ActiveRecord::Base
    belongs_to :category, polymorphic: true
    belongs_to :membership, polymorphic: true

    log_changes(to: :membership) if respond_to?(:log_changes)

    def to_s
      category&.to_s || 'membership category'
    end

  end
end
