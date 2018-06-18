class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [:create]
  
  respond_to :html, :json

end