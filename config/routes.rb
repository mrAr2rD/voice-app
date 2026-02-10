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

  # Projects
  resources :projects

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

  # Translations
  resources :translations, only: %i[index show new create destroy] do
    member do
      get :download
    end
  end

  # Video Builder
  resources :video_builders do
    member do
      get :download
      post :publish
      post :generate_thumbnail
      post :generate_metadata
    end
  end

  # YouTube OAuth
  get "youtube/auth", to: "youtube_auth#auth", as: :youtube_auth
  get "youtube/callback", to: "youtube_auth#callback", as: :youtube_callback
  delete "youtube/disconnect", to: "youtube_auth#disconnect", as: :youtube_disconnect

  # Activities history
  resources :activities, only: [:index]

  # Admin
  namespace :admin do
    root to: "dashboard#index"
    get "settings", to: "settings#index", as: :settings
    patch "settings", to: "settings#update"
  end
end
