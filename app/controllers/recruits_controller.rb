class RecruitsController < ApplicationController
  before_action :set_recruit, only: [:show, :edit, :update, :destroy]

  # GET /recruits
  # GET /recruits.json
  def index
    @recruits = Recruit.all
  end

  # GET /recruits/1
  # GET /recruits/1.json
  def show
  end

  # GET /recruits/new
  def new
    @recruit = Recruit.new
  end

  # GET /recruits/1/edit
  def edit
  end

  # POST /recruits
  # POST /recruits.json
  def create
    @recruit = Recruit.new(recruit_params)

    respond_to do |format|
      if @recruit.save
        format.html { redirect_to @recruit, notice: 'Recruit was successfully created.' }
        format.json { render action: 'show', status: :created, location: @recruit }
      else
        format.html { render action: 'new' }
        format.json { render json: @recruit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recruits/1
  # PATCH/PUT /recruits/1.json
  def update
    respond_to do |format|
      if @recruit.update(recruit_params)
        format.html { redirect_to @recruit, notice: 'Recruit was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @recruit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recruits/1
  # DELETE /recruits/1.json
  def destroy
    @recruit.destroy
    respond_to do |format|
      format.html { redirect_to recruits_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_recruit
      @recruit = Recruit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def recruit_params
      params.require(:recruit).permit(:integer, :integer)
    end
end
