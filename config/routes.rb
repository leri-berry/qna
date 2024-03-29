require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  
  use_doorkeeper
  devise_for :users, controllers: { omniauth_callbacks: 'oauth_callbacks' }

  get 'search', action: :search, controller: 'search'

  namespace :api do
    namespace :v1 do
      resources :profiles, only: [] do
        get :me, on: :collection
        get :all, on: :collection
      end

      resources :questions, except: [:edit, :new] do
        resources :answers, except: [:edit, :new], shallow: true
      end
    end
  end

  namespace :users do
    get '/set_email', to: 'emails#new'
    post '/set_email', to: 'emails#create'
  end

  resources :attachments, only: :destroy
  resources :links, only: :destroy
  resources :awards, only: :index

  concern :voted do
    member do
      patch :like
      patch :dislike
      delete :cancel
    end
  end

  concern :commented do
    member do
      post :make_comment
    end
  end

  resources :questions, concerns: %i[voted commented] do
    resources :answers, concerns: %i[voted commented], shallow: true do
      patch 'best', on: :member
    end
    resources :subscriptions, only: [:create, :destroy], shallow: true
  end

  root to: 'questions#index'

  mount ActionCable.server => '/cable'
end
