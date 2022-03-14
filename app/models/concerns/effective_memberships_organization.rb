# EffectiveMembershipsOrganization
#
# Mark your category model with effective_memberships_organization to get all the includes

module EffectiveMembershipsOrganization
  extend ActiveSupport::Concern

  module Base
    def effective_memberships_organization
      include ::EffectiveMembershipsOrganization
    end
  end

  module ClassMethods
    def effective_memberships_organization?; true; end

    def categories
      []
    end
  end

  included do
    effective_memberships_owner
    acts_as_addressable :billing # effective_addresses
    log_changes(except: [:representatives, :users]) if respond_to?(:log_changes)

    # rich_text_body
    # has_many_rich_texts

    # App scoped
    has_many :applicants, -> { order(:id) }, inverse_of: :organization, as: :organization
    has_many :fee_payments, -> { order(:id) }, inverse_of: :organization, as: :organization

    # Effective scoped
    has_many :representatives, -> { Effective::Representative.sorted },
      class_name: 'Effective::Representative', inverse_of: :organization, dependent: :delete_all

    accepts_nested_attributes_for :representatives, allow_destroy: true

    effective_resource do
      title                 :string
      email                 :string

      phone                 :string
      fax                   :string
      website               :string

      category              :string

      notes                 :text

      roles_mask            :integer
      archived              :boolean

      representatives_count :integer # Counter cache

      timestamps
    end

    scope :deep, -> { includes(:representatives) }
    scope :sorted, -> { order(:title) }

    validates :title, presence: true, uniqueness: true
    validates :email, presence: true
  end

  # Instance Methods
  def to_s
    title.presence || 'organization'
  end

  def membership_present?
    membership.present? && !membership.marked_for_destruction?
  end

  def representative(user:)
    representatives.find { |rep| rep.user_id == user.id }
  end

  # Find or build
  def build_representative(user:)
    representative(user: user) || representatives.build(user: user)
  end

  def users
    representatives.reject(&:marked_for_destruction?).map(&:user)
  end

end
