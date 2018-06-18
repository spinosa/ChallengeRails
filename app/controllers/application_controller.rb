class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  skip_before_action :verify_authenticity_token, if: :jwt_present_and_valid
  #TODO: Only allow root to access over HTML

  protected
  
    def jwt_present_and_valid
      request.headers["HTTP_AUTHORIZATION"] && request.headers["HTTP_AUTHORIZATION"].starts_with?("Bearer")
      #TODO: Make sure JWT is valid
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:screenname])
    end
    
end
