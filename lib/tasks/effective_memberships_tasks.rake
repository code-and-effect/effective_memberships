namespace :effective_memberships do

  # bundle exec rake effective_memberships:seed
  task seed: :environment do
    load "#{__dir__}/../../db/seeds.rb"
  end

  # rake effective_memberships:create_fees
  desc 'Run daily to create Renewal and Late fees'
  task create_fees: :environment do
    if ActiveRecord::Base.connection.table_exists?(:memberships)
      EffectiveLogger.info "Running effective_memberships:create_fees scheduled task" if defined?(EffectiveLogger)
      EffectiveMemberships.Registrar.create_fees!
    end
  end

end
