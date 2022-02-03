module Effective
  class MembershipCardsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    def show
      membership = Effective::Membership.find(params[:membership_id])
      card = EffectiveMemberships.MembershipCard.new(membership: membership)

      EffectiveResources.authorize!(self, :show, membership)
      EffectiveResources.authorize!(self, :show, card)

      send_data(card.to_pdf, filename: card.filename, type: card.content_type, disposition: 'attachment')
    end

  end
end
