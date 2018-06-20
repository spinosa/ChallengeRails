class Users::SearchController < ApplicationController
  before_action :authenticate_user!
  
  # GET /users/screenname
  # GET /users/screenname.json
  def by_screenname
    screenname = params['screenname'].gsub('@', '')
    @users = User.where('screenname LIKE ?', '%' + screenname + '%').all
    @users -= [current_user]
    
    respond_to do |format|
      format.json { render 'users/index', status: :ok }
    end
  end

end