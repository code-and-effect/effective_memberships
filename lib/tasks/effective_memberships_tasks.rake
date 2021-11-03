# bundle exec rake effective_memberships:seed
namespace :effective_memberships do
  task seed: :environment do
    load "#{__dir__}/../../db/seeds.rb"
  end
end
