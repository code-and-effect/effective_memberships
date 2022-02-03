module Effective
  class MembershipCardsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::CrudController

    resource_scope -> { EffectiveMemberships.MembershipCard }

    def show
      membership = Effective::Membership.find(params[:id])
      card = resource_scope.new(membership: membership)

      EffectiveResources.authorize!(self, :show, card)

      send_data(card.to_pdf, filename: card.filename, type: card.content_type, disposition: 'attachment')
    end

  end
end
