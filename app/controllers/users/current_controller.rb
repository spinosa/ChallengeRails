# NON-DEVISE
# Allow current_user to update their information
class Users::CurrentController < ApplicationController
  before_action :authenticate_user!
  
  # GET /users/current.json
  def show
    respond_to do |format|
      format.json { render partial: 'users/user', status: :ok, object: current_user }
    end
  end
  
  # PATCH/OUT /users/current.json
  def update
    respond_to do |format|
      if current_user.update(user_params)
        format.json { render partial: 'users/user', status: :ok, object: current_user }
      else
        format.json { render json: current_user.errors, status: :unprocessable_entity }
      end
    end
  end
  
  private 
  
    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:apns_device_token)
    end

end