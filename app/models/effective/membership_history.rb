module Effective
  class MembershipHistory < ActiveRecord::Base
    belongs_to :owner, polymorphic: true

    effective_resource do
      start_on       :date
      end_on         :date

      number         :string

      bad_standing   :boolean
      removed        :boolean

      categories      :text
      category_ids    :text

      notes          :text

      timestamps
    end

    serialize :categories, Array
    serialize :category_ids, Array

    scope :deep, -> { includes(:owner) }
    scope :sorted, -> { order(:start_on) }

    validates :owner, presence: true

    validates :categories, presence: true, unless: -> { removed? }
    validates :category_ids, presence: true, unless: -> { removed? }

    validates :start_on, presence: true

    def to_s
      'membership history'
    end

  end
end
