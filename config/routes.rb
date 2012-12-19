Ruthieonart::Application.routes.draw do
  devise_for :users, :only => [:sessions, :passwords]

  devise_scope :user do
    get '/login' => 'devise/sessions#new', :as => 'login'
    delete '/logout' => 'devise/sessions#destroy', :as => 'logout'
    get '/reset-password' => 'devise/passwords#new', :as => 'reset_password'
  end

  get '/contact' => 'contact#new', :as => 'contact'

  post '/contact' => 'contact#create'

  resources :pages, :only => [:show]

  resources :posts, :only => [:index, :show]

  get '/sitemap' => 'sitemap#index', :as => 'sitemap'

  authenticate :user do
    namespace :admin do
      root :to => 'admin#index'

      get 'export' => 'admin#export', :as => 'export'

      resource :account, :only => [:show, :edit, :update]

      resources :pages

      resources :pictures do
        collection do
          get :selector
        end
      end

      resources :posts

      resources :users
    end

    post 'versions/:id/revert' => 'versions#revert', :as => 'revert_version'
  end

  root :to => 'posts#index'

  get ':id' => 'pages#show'
end
