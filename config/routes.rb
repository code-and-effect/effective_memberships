Rails.application.routes.draw do
  mount EffectiveMemberships::Engine => '/', as: 'effective_memberships'
end

EffectiveMemberships::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    resources :applicants, only: [:new, :show, :destroy] do
      resources :build, controller: :applicants, only: [:show, :update]
    end

    resources :applicant_references, only: [:new, :create, :show, :update] do
      post :notify, on: :member
    end
  end

  namespace :admin do
    resources :applicants, except: [:new, :create, :show]
    resources :membership_categories, except: [:show]

    resources :applicant_course_areas, except: [:show]
    resources :applicant_course_names, except: [:show]
  end

end
