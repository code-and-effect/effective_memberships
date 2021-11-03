module EffectiveMemberships
  class Engine < ::Rails::Engine
    engine_name 'effective_memberships'

    # Set up our default configuration options.
    initializer 'effective_memberships.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_memberships.rb")
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_memberships.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(EffectiveMembershipsUser::Base)
      end
    end

  end
end
