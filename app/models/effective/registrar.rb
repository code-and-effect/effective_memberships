module Effective
  class Registrar

    def register!(user, to:)
      raise('expecting a memberships user') unless user.class.respond_to?(:effective_memberships_user?)
      raise('expecting a memberships category') unless to.class.respond_to?(:effective_memberships_category?)

    end

  end
end
