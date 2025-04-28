Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    
    namespace :v1 do
      post "authen/login", to: "authentication#login"
      post "authen/register", to: "authentication#register"

      # Các route của Assets
      get "assets", to: "assets#index"
      post "assets", to: "assets#create"
      post "assets/bulk_import", to: "assets#bulk_import"

      # Các route của Purchases
      get "purchases", to: "purchases#index"
      post "purchases", to: "purchases#create"
      get "purchases/download", to: "purchases#download"
      namespace :admin do
        get 'earnings', to: 'earnings#index'
      end
    end
  end

  # User authentication routes would go here
  # For simplicity, we are skipping those

  root "assets#index"
end
