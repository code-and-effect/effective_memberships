Rails.application.routes.draw do
  mount EffectiveMemberships::Engine => '/', as: 'effective_memberships'
end

EffectiveMemberships::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    resources :applicants, only: [:new, :show, :destroy] do
      resources :build, controller: :applicants, only: [:show, :update]
    end
  end

  namespace :admin do
    resources :applicants, except: [:new, :create, :show]
    resources :membership_categories, except: [:show]
  end

end
