Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  resources :bills, only: [:index, :show] do
    collection do
      post :vote
    end
  end
  root 'bills#index'
end
