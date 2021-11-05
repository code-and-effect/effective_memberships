Rails.application.routes.draw do
  mount EffectiveMemberships::Engine => '/', as: 'effective_memberships'
end

EffectiveMemberships::Engine.routes.draw do
  scope module: 'effective' do
    # Public routes
  end

  namespace :admin do
    resources :applicants, except: [:new, :create, :show]
    resources :membership_categories, except: [:show]
  end

end
