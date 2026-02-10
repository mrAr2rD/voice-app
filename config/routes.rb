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

  # Cloned Voices (Voice Cloning)
  resources :cloned_voices, only: %i[index show new create destroy]

  # Batch Jobs (Batch Processing)
  resources :batch_jobs, only: %i[index show new create destroy]

  # Scripts (AI Script Writer)
  resources :scripts, only: %i[index show new create destroy] do
    member do
      post :copy_to_tts
    end
  end

  # Video Clips (Auto-Clipping for Shorts/Reels)
  resources :video_clips, only: %i[index show new create destroy] do
    member do
      get :download
    end
    collection do
      post :auto_detect
      post :bulk_create
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

  # YouTube Analytics
  get "youtube/analytics", to: "youtube_analytics#index", as: :youtube_analytics
  get "youtube/analytics/:id", to: "youtube_analytics#show", as: :youtube_analytics_video

  # Social Accounts (Multi-platform)
  resources :social_accounts, only: %i[index destroy]
  get "social/auth/:platform", to: "social_accounts#auth", as: :social_auth
  get "social/callback/:platform", to: "social_accounts#callback", as: :social_callback

  # Scheduled Posts
  resources :scheduled_posts, only: %i[index show new create destroy]

  # Activities history
  resources :activities, only: [ :index ]

  # Admin
  namespace :admin do
    root to: "dashboard#index"
    get "settings", to: "settings#index", as: :settings
    patch "settings", to: "settings#update"
  end
end
