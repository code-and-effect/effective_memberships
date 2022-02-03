# frozen_string_literal: true

# EffectiveMembershipsCard
# Mark your card model with include EffectiveMembershipsCard to get all the includes

module EffectiveMembershipsCard
  extend ActiveSupport::Concern

  module ClassMethods
    def effective_memberships_card?; true; end
  end

  included do
    include ActiveModel::Model

    attr_accessor :membership
    validates :membership, presence: true
  end

  # Instance Methods
  def owner
    membership&.owner
  end

  def content_type
    'application/pdf'
  end

  def filename
    "#{self.class.name.split('::').first.downcase}-membership-card-#{Time.zone.now.strftime('%F')}.pdf"
  end

  def to_pdf
    raise('is invalid') unless valid?

    return pdf.render() if pdf.respond_to?(:render) # Prawn
    return pdf.to_pdf() if pdf.respond_to?(:to_pdf) # CombinePdf

    pdf
  end

  def pdf
    @pdf ||= build_pdf()
  end

  private

  def build_pdf()
    raise('to be implemented')

    # pdf = Prawn::Document.new
    # pdf.text("Membership Card for #{membership.owner} Number #{membership.number}")
    # pdf
  end

end
