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
  
end
