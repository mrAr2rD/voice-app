Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "home#index"

  # Authentication
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Profile
  resource :profile, only: %i[show edit update]

  # Transcriptions
  resources :transcriptions, only: %i[index show new create destroy] do
    member do
      post :retry
      get :download
    end
  end

  # Voice Generations
  resources :voice_generations, only: %i[index show new create destroy] do
    member do
      get :download
    end
    collection do
      get :voices
    end
  end

  # Admin
  namespace :admin do
    root to: "dashboard#index"
    get "settings", to: "settings#index", as: :settings
    patch "settings", to: "settings#update"
  end
end
