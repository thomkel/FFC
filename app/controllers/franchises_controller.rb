class FranchisesController < ApplicationController
  before_action :set_franchise, only: [:show, :edit, :update, :destroy]

  # GET /franchises
  # GET /franchises.json
  def index
    @franchises = Franchise.all
  end

  # GET /franchises/1
  # GET /franchises/1.json
  def show
  end

  # GET /franchises/new
  def new
    @franchise = Franchise.new
  end

  # GET /franchises/1/edit
  def edit
  end

  # POST /franchises
  # POST /franchises.json
  def create
    @franchise = Franchise.new(franchise_params)

    respond_to do |format|
      if @franchise.save
        format.html { redirect_to @franchise, notice: 'Franchise was successfully created.' }
        format.json { render action: 'show', status: :created, location: @franchise }
      else
        format.html { render action: 'new' }
        format.json { render json: @franchise.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /franchises/1
  # PATCH/PUT /franchises/1.json
  def update
    respond_to do |format|
      if @franchise.update(franchise_params)
        format.html { redirect_to @franchise, notice: 'Franchise was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @franchise.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /franchises/1
  # DELETE /franchises/1.json
  def destroy
    @franchise.destroy
    respond_to do |format|
      format.html { redirect_to franchises_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_franchise
      @franchise = Franchise.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def franchise_params
      params.require(:franchise).permit(:integer, :integer)
    end
end
