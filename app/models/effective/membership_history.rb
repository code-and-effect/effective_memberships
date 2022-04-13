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

    scope :removed, -> { where(removed: true) }

    validates :owner, presence: true

    # validates :categories, presence: true, unless: -> { removed? }
    # validates :category_ids, presence: true, unless: -> { removed? }

    validates :start_on, presence: true

    def to_s
      'membership history'
    end

    # These two accessors are for the memberships history form.
    # But we just assign categories and category_ids directly in registrar.
    def membership_categories
      category_ids.present? ? EffectiveMemberships.Category.where(id: category_ids) : []
    end

    def membership_category_ids
      membership_categories.map(&:id)
    end

    def membership_category_ids=(ids)
      categories = EffectiveMemberships.Category.where(id: ids)
      assign_attributes(categories: categories.map(&:to_s), category_ids: categories.map(&:id))
    end

  end
end
