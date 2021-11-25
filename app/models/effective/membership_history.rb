module Effective
  class MembershipHistory < ActiveRecord::Base
    belongs_to :user, polymorphic: true

    belongs_to :membership_category, polymorphic: true

    effective_resource do
      start_on       :date
      end_on         :date

      number              :string
      in_bad_standing     :boolean

      notes               :text

      timestamps
    end

    serialize :extra, Hash

    scope :deep, -> { includes(:user, :category) }
    scope :sorted, -> { order(:start_on) }

    validates :start_on, presence: true

    def to_s
      'membership history'
    end

  end
end
