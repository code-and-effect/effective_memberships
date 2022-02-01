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

    resources :fee_payments, only: [:new, :show] do
      resources :build, controller: :fee_payments, only: [:show, :update]
    end

    get '/directory', to: 'memberships_directory#index'
  end

  namespace :admin do
    resources :applicants, except: [:new, :create, :show]

    resources :applicant_references do
      post :notify, on: :member
    end

    resources :fees
    resources :categories, except: [:show]

    resources :applicant_course_areas, except: [:show]
    resources :applicant_course_names, except: [:show]

    resources :fee_payments, only: [:index, :show]
    resources :memberships, only: [:index]
    resources :registrar_actions, only: [:create]
  end

end
