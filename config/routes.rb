Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "admin", to: "admin/dashboard#index"
  get "admin/games/:id", to: "admin/dashboard#show_game", as: :admin_game

  namespace :api do
    namespace :v1 do
      post "auth", to: "auth#create"
      get "me", to: "users#me"

      resources :games, only: %i[index create show] do
        member do
          post :join
          post :start
        end

        resources :moves, only: %i[index create]
      end
    end
  end
end
