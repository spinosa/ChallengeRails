class BattlesController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  
  before_action :set_battle, only: [:show, :edit, :update, :cancel, :decline, :accept, :complete, :dispute, :destroy]

  # GET /battles
  # GET /battles.json
  def index
    @battles = Battle.where.not(recipient_id: nil)
    
    if current_user
      if params[:outbox]
         @battles = @battles.where(initiator: current_user)
       elsif params[:inbox]
         @battles = @battles.where(recipient: current_user)
       elsif params[:myActive]
         @battles = @battles.where(initiator: current_user).or(Battle.where(recipient: current_user))
           .where(state: Battle::BattleState::ALL_ACTIVE)
       elsif params[:myArchive]
         @battles = @battles.where(initiator: current_user).or(Battle.where(recipient: current_user))
         .where(state: Battle::BattleState::ALL_ARCHIVE)
       end
    end

    #TODO: Pagination
    @battles = @battles.order(created_at: :desc).includes([:initiator, :recipient]).all
  end

  # GET /battles/1
  # GET /battles/1.json
  def show
  end

  # GET /battles/new
  def new
    @battle = Battle.new
  end

  # GET /battles/1/edit
  def edit
  end

  # POST /battles
  # POST /battles.json
  def create
    @battle = Battle.new(battle_params.merge({
      initiator: current_user, 
      outcome: Battle::Outcome::TBD, 
      state: Battle::BattleState::OPEN, 
      disputed_at: nil
      })
    )

    respond_to do |format|
      if @battle.save
        format.html { redirect_to @battle, notice: 'Battle was successfully created.' }
        format.json { render :show, status: :created, location: @battle }
      else
        format.html { render :new }
        format.json { render json: @battle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /battles/1
  # PATCH/PUT /battles/1.json
  def update
    respond_to do |format|
      if current_user.can_update_battle?(@battle) and @battle.update(battle_params)
        format.html { redirect_to @battle, notice: 'Battle was successfully updated.' }
        format.json { render :show, status: :ok, location: @battle }
      else
        format.html { render :edit }
        format.json { render json: @battle.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # POST /battles/1b-cd-2e/cancel
  def cancel
    respond_to do |format|
      if current_user.can_update_battle?(@battle) and @battle.cancel(current_user) and @battle.save
        format.html { redirect_to @battle, notice: 'Battle has been withdrawn.' }
        format.json { render :show, status: :ok, location: @battle }
      else
        format.html { render :show }
        format.json { render json: @battle.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # POST /battles/1b-cd-2e/decline
  def decline
    respond_to do |format|
      if current_user.can_update_battle?(@battle) and @battle.decline(current_user) and @battle.save
        format.html { redirect_to @battle, notice: 'Battle has been declined.' }
        format.json { render :show, status: :ok, location: @battle }
      else
        format.html { render :show }
        format.json { render json: @battle.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # POST /battles/1b-cd-2e/accept
  def accept
    respond_to do |format|
      if current_user.can_update_battle?(@battle) and @battle.accept(current_user) and @battle.save
        format.html { redirect_to @battle, notice: 'Battle was successfully accepted!' }
        format.json { render :show, status: :ok, location: @battle }
      else
        format.html { render :show }
        format.json { render json: @battle.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # POST /battles/1b-cd-2e/complete
  def complete
    respond_to do |format|
      if current_user.can_update_battle?(@battle) and @battle.complete(params[:outcome], current_user) and @battle.save
        format.html { redirect_to @battle, notice: 'Battle is now complete!  Good for you. ;-]' }
        format.json { render :show, status: :ok, location: @battle }
      else
        format.html { render :show }
        format.json { render json: @battle.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # POST /battles/1b-cd-2e/dispute
  def dispute
    respond_to do |format|
      if current_user.can_update_battle?(@battle) and @battle.dispute(current_user) and @battle.save
        format.html { redirect_to @battle, notice: 'Battle is marked disputed.' }
        format.json { render :show, status: :ok, location: @battle }
      else
        format.html { render :show }
        format.json { render json: @battle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /battles/1
  # DELETE /battles/1.json
  def destroy
    respond_to do |format|
      if current_user.is_root
        @battle.destroy
        format.html { redirect_to battles_url, notice: 'Battle was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { render :show }
        format.json { render json: @battle.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_battle
      @battle = Battle.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def battle_params
      params.require(:battle).permit(:description, :recipient_screenname, :invited_recipient_email, :invited_recipient_phone_number)
    end
end
