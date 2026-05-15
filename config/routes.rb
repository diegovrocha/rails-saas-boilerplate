Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  resources :accounts, only: %i[show edit update] do
    member { post :switch }
  end

  resources :account_users, only: %i[index create update destroy]

  namespace :billing do
    resource :checkout, only: %i[create] do
      get :success, on: :collection
      get :cancel,  on: :collection
    end
    resource :portal, only: %i[create]
  end

  namespace :webhooks do
    post "stripe" => "stripe#create"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
