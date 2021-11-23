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
    has_many :applicants
    has_many :fees
    has_many :fee_payments

    has_one :membership, inverse_of: :user, class_name: 'Effective::Membership'
    accepts_nested_attributes_for :membership

    has_many :membership_histories, -> { Effective::MembershipHistory.sorted }, inverse_of: :user, class_name: 'Effective::MembershipHistory'
    accepts_nested_attributes_for :membership_histories

    effective_resource do
      timestamps
    end
  end

  def outstanding_fee_payment_fees
    fees.select { |fee| fee.fee_payment_fee? && !fee.purchased? }
  end

  # Instance Methods
  def build_prorated_fees(date: nil)
    raise('must have an existing membership') unless membership.present?

    date ||= Time.zone.now
    period = EffectiveMemberships.Registrar.current_period(date: date)
    price = membership.category.send("prorated_#{date.strftime('%b').downcase}").to_i

    fee = fees.find { |fee| fee.category == 'Prorated' } || fees.build()
    fee.assign_attributes(category: 'Prorated', period: period, price: price, due_at: date)

    fee
  end

  def build_membership_history(start_on: nil)
    raise('expected membership to be present') unless membership.present?

    # The date of change
    start_on ||= Time.zone.now

    # End the other membership histories
    membership_histories.each { |history| history.end_on ||= start_on }

    # Snapshot of the current membership at this time
    membership_histories.build(
      start_on: start_on,
      end_on: nil,
      membership_category: membership.category,
      number: membership.number,
      in_bad_standing: membership.in_bad_standing?
    )
  end

  def membership_history_on(date)
    raise('expected a date') unless date.respond_to?(:strftime)
    membership_histories.find { |history| (history.start_on..history.end_on).cover?(date) } # Ruby 2.6 supports endless ranges
  end

end
