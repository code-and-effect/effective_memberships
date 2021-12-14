module Effective
  class MembershipHistory < ActiveRecord::Base
    belongs_to :owner, polymorphic: true
    belongs_to :membership_category, polymorphic: true, optional: true

    effective_resource do
      start_on       :date
      end_on         :date

      number         :string

      bad_standing   :boolean
      removed        :boolean

      notes          :text

      timestamps
    end

    serialize :extra, Hash

    scope :deep, -> { includes(:owner, :membership_category) }
    scope :sorted, -> { order(:start_on) }

    validates :owner, presence: true
    validates :membership_category, presence: true, unless: -> { removed? }

    validates :start_on, presence: true

    def to_s
      'membership history'
    end

  end
end
