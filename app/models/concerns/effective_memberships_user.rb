# EffectiveMembershipsUser
#
# Mark your user model with effective_memberships_user to get all the includes

module EffectiveMembershipsUser
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_user
      include ::EffectiveMembershipsUser
    end
  end

  module ClassMethods
    def effective_memberships_user?; true; end
  end

  included do
    attr_accessor :membership_change_date

    has_many :applicants
    has_many :fees

    has_one :membership, class_name: 'Effective::Membership'
    accepts_nested_attributes_for :membership

    has_many :membership_histories, -> { Effective::MembershipHistory.sorted }, class_name: 'Effective::MembershipHistory'
    accepts_nested_attributes_for :membership_histories

    effective_resource do
      timestamps
    end

    validate(if: -> { membership_change_date.present? }) do
      if membership_change_date > Time.zone.now.to_date
        errors.add(:membership_change_date, "can't be in the future")
      elsif membership_change_date < (Time.zone.now - 1.year).to_date
        errors.add(:membership_change_date, "can't be more than 1 year in the past")
      end
    end

  end

  # Instance Methods
  def build_membership_history(start_on: nil)
    raise('expected membership to be present') unless membership.present?

    # The date of change
    start_on ||= (membership_change_date || Time.zone.now)

    # End the other membership histories
    membership_histories.each { |history| history.end_on ||= start_on }

    # Snapshot of the current membership at this time
    membership_histories.build(
      start_on: start_on,
      end_on: nil,
      membership_category: membership.category,
      number: membership.number,
      in_bad_standing: membership.in_bad_standing
    )
  end

  def membership_history_on(date)
    raise('expected a date') unless date.respond_to?(:strftime)
    membership_histories.find { |history| (history.start_on..history.end_on).cover?(date) } # Ruby 2.6 supports endless ranges
  end

end
