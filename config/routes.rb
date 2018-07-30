Rails.application.routes.draw do
  
  root to: "battles#index"
  
  devise_for :users, :controllers => {registrations: 'users/registrations', sessions: 'users/sessions'}
  
  resources :battles do
    post 'cancel',   on: :member, to: 'battles#cancel',   as: :cancel
    post 'decline',  on: :member, to: 'battles#decline',  as: :decline
    post 'accept',   on: :member, to: 'battles#accept',   as: :accept
    post 'complete', on: :member, to: 'battles#complete', as: :complete #with params: outcome=X
    post 'dispute',  on: :member, to: 'battles#dispute',  as: :dispute
  end
  
  namespace :users do
    get 'search/screenname/:screenname', to: 'search#by_screenname', as: :search_by_screenname
  end
  
  # current user
  get 'current_user', to: 'users/current#show', as: :show_current_user
  patch 'current_user', to: 'users/current#update', as: :update_current_user
  
  get 'apple-app-site-association', to: 'well_known#apple_app_site_association'
  get '.well-known/apple-app-site-association', to: 'well_known#apple_app_site_association'
end
