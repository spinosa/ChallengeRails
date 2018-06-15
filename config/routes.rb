Rails.application.routes.draw do
  
  root to: "battles#new"
  
  devise_for :users
  resources :battles
  
end
