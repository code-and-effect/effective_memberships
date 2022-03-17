# frozen_string_literal: true

module Effective
  class Representative < ActiveRecord::Base
    attr_accessor :new_representative_user_action

    acts_as_role_restricted

    log_changes(to: :organization) if respond_to?(:log_changes)

    belongs_to :organization, polymorphic: true, counter_cache: true
    belongs_to :user, polymorphic: true

    accepts_nested_attributes_for :organization
    accepts_nested_attributes_for :user

    effective_resource do
      roles_mask    :integer

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:user, :organization) }

    before_validation(if: -> { user && user.new_record? }) do
      user.password ||= SecureRandom.base64(12) + '!@#123abcABC-'
    end

    after_commit(on: [:create, :destroy], if: -> { user.class.respond_to?(:effective_memberships_owner?) }) do
      user.representatives.reload
      user.update_member_role!
    end

    validates :organization, presence: true
    validates :user, presence: true

    validates :user_id, if: -> { user_id && user_type && organization_id && organization_type },
      uniqueness: { scope: [:organization_id, :organization_type], message: 'already belongs to this organization' }

    def to_s
      user.to_s
    end

    def build_user(attributes = {})
      raise('please assign user_type first') if user_type.blank?
      self.user = user_type.constantize.new(attributes)
    end

    def build_organization(attributes = {})
      raise('please assign organization_type first') if organization_type.blank?
      self.organization = organization_type.constantize.new(attributes)
    end

  end
end
