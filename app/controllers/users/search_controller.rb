class Users::SearchController < ApplicationController
  before_action :authenticate_user!
  
  # GET /users/screenname
  # GET /users/screenname.json
  def by_screenname
    @users = User.where('screenname LIKE ?', '%' + params['screenname'] + '%').all
    @users -= [current_user]
    
    respond_to do |format|
      format.json { render 'users/index', status: :ok }
    end
  end

end