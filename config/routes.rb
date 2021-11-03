Rails.application.routes.draw do
  mount EffectiveMemberships::Engine => '/', as: 'effective_memberships'
end

EffectiveMemberships::Engine.routes.draw do
  scope module: 'effective' do
  end

  namespace :admin do
    resources :membership_categories, except: [:show]
  end

end
