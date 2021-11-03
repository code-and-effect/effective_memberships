# It's expected the app will extend this class

module Effective
  class MembershipCategory < ActiveRecord::Base
    log_changes if respond_to?(:log_changes)

    has_rich_text :body
    has_many :users

    effective_resource do
      title                 :string       # 2021 Continuing Professional Development
      position              :integer

      can_apply             :boolean

      applicant_fee         :integer
      annual_fee            :integer

      timestamps
    end

    scope :deep, -> { with_rich_text_body }

    scope :sorted, -> { order(:title) }
    scope :can_apply, -> { where(can_apply: true) }

    validates :title, presence: true, uniqueness: true
    validates :position, presence: true

    before_validation do
      self.position ||= (self.class.pluck(:position).compact.max || -1) + 1
    end

    def to_s
      title.presence || 'New Membership Category'
    end

  end
end
