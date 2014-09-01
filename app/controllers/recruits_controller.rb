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

  #POST
  def upload_recruits
    @league_id = params[:league_id]

    if !params[:file].nil?
      @file = params[:file]

      CSV.foreach(File.path(@file.path)) do |player|      

        if !player[0].nil?
          player_data = player[0].split(",")
          player_name = player_data[0].gsub("*", "")
          player_data = player_data[1].split(/[[:space:]]/)

          player_position = player_data[2]
          player_points = player[1]
    
          found_player = Player.find_by(:name => player_name)
          player_id = nil

          if found_player.nil?
            new_player = Player.new
            new_player.name = player_name
            new_player.position = standardize_position(player_position)
            new_player.save

            player_id = new_player.id
          else
            player_id = found_player.id
          end

          recruit = Recruit.new
          recruit.player_id = player_id
          recruit.projected_points = player_points
          recruit.league_id = @league_id
          recruit.save            
        end
      end

    else
      redirect_to "/add_recruits/#{@league_id}", notice: "Not a valid file or no file selected"

    end      

      redirect_to "/add_recruits/#{@league_id}", notice: "Recruits successfully uploaded"
    
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

  def standardize_position(position)
    if position == "DE" || position == "DT"
      return "DL"
    elsif position == "S" || position == "CB"
      return "DB"
    elsif position == "D/ST"
      position = "DEF"
    else
      return position
    end
  end  

  # def open_file(file)
  #   case File.extname(file.original_filename)
  #   when ".csv" then Roo::Csv.new(file.path, nil, :ignore)
  #   when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
  #   when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
  #   else raise "Unknown file type: #{file.original_filename}"
  #   end
  # end  

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
