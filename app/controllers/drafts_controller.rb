class DraftsController < ApplicationController
  before_action :set_draft, only: [:show, :edit, :update, :destroy]

  # GET /drafts
  # GET /drafts.json
  def index
    @drafts = Draft.all
  end

  def keepers
    @keepers = Recruit.where('last_year_points > 0')
  end

  def add_pick

    player_name = params[:player]
    player_like = "%#{player_name}%"
    @players_found = Player.where("lower(name) LIKE ?", player_like.downcase)

    @picks = Pick.where(:draft_id => session[:draft_id])

    if @players_found.size == 1
      player = @players_found.first
      team, round = find_team_by_pick_num(session[:pick_number])

      pick = Pick.new
      pick.draft_id = session[:draft_id]
      pick.pick_num = session[:pick_number]
      pick.team_id = team.id
      pick.player_id = player.id
      pick.round = round
      pick.save      

      session[:pick_number] += 1

      while (session[:pick_number] <= 200) && (!@picks.find_by(:pick_num => session[:pick_number]).nil?)
        session[:pick_number] += 1
      end

      initialize_simulation(session[:draft_id])    

      #elsif need errors
    elsif @players_found.size == 0
      initialize_simulation(session[:draft_id])
    elsif @players_found.size > 1
      initialize_simulation(session[:draft_id])
    end


  end

  def initialize_draft
    # intialize teams
    league = League.find_by(:name => "Speeding Utility Ram")
    @teams = Team.where(:league_id => league.id) 
    rounds = 20 
    session[:myteam] = "Team 1 - Me"
    session[:num_picks] = @teams.count * rounds    
    session[:pick_number] = 1

    olddraft = Draft.find_by(:name => "Speeding Utility 2014")

    if !olddraft.nil?
      Pick.where(:draft_id => olddraft.id).destroy_all
      olddraft.destroy
    end

    draft = Draft.new
    draft.name = "Speeding Utility 2014"
    draft.draft_type = "Snake"
    draft.league_id = league.id
    draft.num_rounds = 20
    draft.save

    session[:draft_id] = draft.id



    #initialize array of picks
    session[:draft_order] = ["Team 8 - JD", "Team 10 - Dan", "Team 6 - Josh", "Team 7 - Tony", "Team 5 - Mark", "Team 1 - Me", "Team 3 - Calen", "Team 9 - Brett", "Team 2 - Tim", "Team 4 - Matt"]        
    session[:draft_trades] = { ["Team 4 - Matt", 16] => "Team 2 - Tim", ["Team 2 - Tim", 7] => "Team 4 - Matt", ["Team 2 - Tim", 10] => "Team 4 - Matt", ["Team 8 - JD", 8] => "Team 1 - Me", ["Team 1 - Me", 13] => "Team 8 - JD" }

    # positions
    session[:num_starters] = { "QB" => 1, "RB" => 2, "WR" => 2, "TE" => 1, "FLEX" => 1, "LB" => 1, "DL" => 1, "DB" => 1, "K" => 1, "HC" => 1 }
    session[:max_per_position] = { "QB" => 2, "RB" => 5, "WR" => 5, "TE" => 2, "FLEX" => nil, "LB" => 3, "DL" => 4, "DB" => 4, "K" => 3, "HC" => 2, "BENCH" => 8, "IR" => 2 }    

    # initialize available players
    # queue players
    players = Recruit.order('projected_points desc')
    @qbs, @rbs, @wrs, @tes, @lbs, @dls, @dbs, @ks, @hcs = queue_players(players)    
    queues = { "QB" => @qbs, "RB" => @rbs, "WR" => @wrs, "TE" => @tes, "LB" => @lbs, "DL" => @dls, "DB" => @dbs, "K" => @ks, "HC" => @hcs }
    @num_players_per_position = initialize_players_per_position(@teams, session[:num_starters])        

    @keepers = ["Drew Brees", "A.J. Green", "Victor Cruz", "Dez Bryant", "DeMarco Murray",
      "Michael Crabtree", "Matt Forte", "Calvin Johnson", "Jay Cutler", "Rashad Jennings", "Julius Thomas", 
      "Demaryius Thomas", "Rob Gronkowski", "Stephen Gostkowski", "Eddie Lacy", "Marshawn Lynch", "Jamaal Charles", "Greg Olsen",
      "Adrian Peterson", "Brandon Marshall", "Giovani Bernard", "Percy Harvin", "Jordan Cameron", "Peyton Manning", "Julio Jones",
      "LeSean McCoy", "Mike Wallace", "Colin Kaepernick", "Doug Martin", "Jimmy Graham", "Le'Veon Bell", "Zac Stacy", "Eagles Coach",
      "Aaron Rodgers", "Vernon Davis", "DeSean Jackson", "Alshon Jeffery", "Montee Ball"]    

    initialize_picks(session[:draft_order], draft.draft_type, @keepers, queues, @num_players_per_position)    

    @picks = Pick.where(:draft_id => session[:draft_id])

    initialize_simulation(draft.id)
  end

  def initialize_picks(draft_order, draft_type, keepers, player_queues, positions_on_team)
    if draft_type == "Snake" 
      ascending = true
      num_picks = 200
      pick_order = 1  
      round = 1

      queues = player_queues
      players_per_position = positions_on_team

      @keeper_picks = initialize_keeper_picks(keepers)

      for pick in 1..200

        index = pick_order - 1
        team = Team.find_by(:name => draft_order[index])        

        keeper = @keeper_picks[[round,team.id]]

        if !keeper.nil?
          # @picks[[pick,team.id]] = keeper.name

          # move to method create_new_pick
          pick_new = Pick.new
          pick_new.draft_id = session[:draft_id]
          pick_new.pick_num = pick
          pick_new.team_id = team.id
          pick_new.player_id = keeper.id 
          pick_new.round = round
          pick_new.save

          # update position counts
          player = Player.find_by(:name => keeper.name)
          position = player.position
          index = team.name + position
          # @num_players_per_position[index] += 1

          #remove player from available player queue
          queues, players_per_position = remove_player_from_queue(player, team, queues, players_per_position)
        end

        # change draft order
        if ascending & (pick_order < 10)
          pick_order += 1
        elsif ascending
          ascending = false
          round += 1
        elsif !ascending & (pick_order > 1)
          pick_order -= 1
        else
          ascending = true
          round += 1
        end     
      end 


    end

  end

  def remove_player_from_queue(player, team, player_queues, positions_on_team)

    queues = player_queues
    players_per_position = positions_on_team

    recruit = Recruit.find_by(:player_id => player.id)

    # establish flexkey
    position = player.position
    key = team.name + position
    flexkey = team.name + "FLEX"

    queues[position].delete(recruit)

    # check if need to update flex
    if (position == "RB" || position == "WR" || position == "TE") 
      num = players_per_position[key]

      if ((num == session[:num_starters][position]) && (players_per_position[flexkey] == 0))
        players_per_position[flexkey] = 1
      end
    end

    players_per_position[key] += 1
 
    return queues, players_per_position

  end

  def initialize_keeper_picks(keepers)
    keeper_picks = Hash.new

    keepers.each do |keeper|
      player_info = Player.find_by(:name => keeper)
      position = player_info.position
      player_name = player_info.name
      pick = Pick.find_by(:player_id => player_info.id) 
      team = Recruit.find_by(:player_id => player_info.id).team_id

      if (pick.nil?) || (pick.round == 20)
        round = 20
      else
        round = (pick.round + 1)
      end   

      keeper_picks[[round,team]] = player_info

    end

    return keeper_picks

  end

  def initialize_players_per_position(teams, positions)
    num_players_per_position = Hash.new(0)

    teams.each do |team|
      positions.each do |position, num|
        string = team.name + position

        num_players_per_position[string] = 0
      end
    end    

    return num_players_per_position
  end

  def initialize_simulation(draft_id)
    picks = Pick.where(:draft_id => draft_id)
    players = Recruit.order('projected_points desc') 

    @sim_qbs, @sim_rbs, @sim_wrs, @sim_tes, @sim_lbs, @sim_dls, @sim_dbs, @sim_ks, @sim_hcs = queue_players(players)

    queues = { "QB" => @sim_qbs, "RB" => @sim_rbs, "WR" => @sim_wrs, "TE" => @sim_tes, "LB" => @sim_lbs, "DL" => @sim_dls, "DB" => @sim_dbs, "K" => @sim_ks, "HC" => @sim_hcs }

    league_id = Draft.find_by(:id => session[:draft_id]).league_id
    @sim_num_players_per_position = initialize_players_per_position(Team.where(:league_id => league_id), session[:num_starters])        

    @sim_picks = []

    picks.each do |pick|
      pick_num = pick.pick_num
      player = Player.find_by(:id => pick.player_id)
      team = Team.find_by(:id => pick.team_id)


      @sim_picks[pick_num] = [player.name, player.position, team.name]
      queues, @sim_num_players_per_position = remove_player_from_queue(player, team, queues, @sim_num_players_per_position)        

    end    

    @sim_picks = simulate_draft(@sim_picks, queues, @sim_num_players_per_position)    

    @suggest_picks = suggest_picks(drafted, available, players_per_position)

    # if myteam, run loop with simulate draft
    # found_suggestions = false
    # suggestions = []

    # if (@nextteam == session[:myteam])

    #   @test_picks = @sim_picks

    #   while found_suggestions = false

    #     suggest_picks(@test_picks)
    #   end
    # end    

    render 'initialize_draft'         

  end

  def simulate_draft(picks, queues, players_per_position)

    ascending = true
    pick_order = 1
    round = 1

    for pick in 1..session[:num_picks]
      index = pick_order - 1
      team = Team.find_by(:name => session[:draft_order][index])

      trade = session[:draft_trades][[team.name,round]]

      if !trade.nil?
        team = Team.find_by(:name => trade)
      end

      is_keeper = picks[pick]

      if is_keeper == nil   #not a keeper chosen

        max = 0
        max_player = nil

        draftees = []
        queues.each do |position, players|
          draftees.push(players[0])
        end

        draftees.each do |draftee|

          if !draftee.nil?
            draftee = Player.find_by(:id => draftee.player_id)
            position = draftee.position

            key = team.name + position
            flexkey = team.name + "FLEX"
            num_players_in_position = players_per_position[key]

            if num_players_in_position < session[:num_starters][position]
              mult = 1
            elsif ((num_players_in_position == session[:num_starters][position]) && (position == "RB" || position == "WR" || position == "TE") && (players_per_position[flexkey] == 0))
              mult = 1
            elsif num_players_in_position < session[:max_per_position][position]
              mult = (session[:num_starters][position].to_f / 16).to_f
            else
              mult = 0
            end

            points = Recruit.find_by(:player_id => draftee.id).projected_points
            mult_points = (points.to_f * mult).to_f

            if (mult_points) > max
              max = mult_points
              @projected = points
              max_player = draftee
            end
          end
        end

        if !max_player.nil?
          picks[pick] = [max_player.name, max_player.position, team.name]
          remove_player_from_queue(max_player, team, queues, players_per_position)
        end        

      end

      # change draft order
      if ascending & (pick_order < 10)
        pick_order += 1
      elsif ascending
        ascending = false
        round+=1
      elsif !ascending & (pick_order > 1)
        pick_order -= 1
      else
        ascending = true
        round+=1
      end

    end

  end

  def suggest_picks(picks)

    @positions_picked = find_positions_picked(session[:pick_number])

  end

  def find_positions_picked(pick_this_round)
    nextpick = pick_this_round + 1
    nextpick_team, round = find_team_by_pick_num(nextpick)

    positions_picked = []

    while (nextpick_team.name != session[:myteam]) && (round < 21)

      nextpick += 1

      nextpick_team, round = find_team_by_pick_num(nextpick)

      position = @sim_picks[nextpick][1]

      if !positions_picked.include?(position)
        positions_picked.push(position)
      end

    end

    return positions_picked, round

  end

  def predict_keepers(simpicks)

    league = League.find_by(:name => "Speeding Utility Ram")
    teams = Team.where(:league_id => league.id)  

    @keepers_per_team = []
    default_points = {"QB" => 271, "RB" => 227, "WR" => 169, "TE" => 104, "DL" => 118, "DB" => 139, "LB" => 181, "K" => 126, "HC" => 41} 

    teams.each do |team|
      team_players = Recruit.where(:team_id => team.id)

      keepers = []

      team_players.each do |player|
        if !player.projected_points.nil?
          pick = Pick.find_by(:player_id => player.player_id)
          player_info = Player.find_by(:id => player.player_id)
          position = player_info.position
          player_name = player_info.name

          if pick.nil?
            round = 20
          else
            round = (pick.round + 1)
          end

          round_pick = ((round * 10) - 9) + 10

          while round_pick < simpicks.size 
            if simpicks[round_pick-1][3] == team.name
              break
            end
            round_pick += 1
          end

          comp_points = 0

          while round_pick < simpicks.size
            if simpicks[round_pick-1][2] == position
              comp_player = Player.find_by(:name => simpicks[round_pick-1][1])
              comp_player_id = comp_player.id
              comp_player_name = comp_player.name
              comp_points = Recruit.find_by(:player_id => comp_player_id).projected_points
              break
            else
              round_pick += 1
            end
          end

          if comp_points == 0
            comp_points = default_points[position]
            comp_player_name = "default"
          end

          point_dif = player.projected_points - comp_points
          player_cost = player.last_year_points

          player_data = [player_name, round, point_dif, player_cost, comp_player_name]
          keepers.push(player_data)

        end

      end

      @keepers_per_team.push(keepers)

      # run knapsack on team hashes to find best option
    end

    return @keepers_per_team
  end

  def knapsack_keepers(keepers, max_cost)
    # rows equal player points
    # columns equals total points (lowest value up to max_points)
    cost_index = 3
    points_index = 2
    name_index = 0

    #sort players by points
    max_values = Hash.new(0)
    max_values_players = Hash.new("")

    keepers = keepers.sort_by {|p| p[cost_index]}

    # set values 0..end to 0
    for i in 0..keepers.size-1
      max_values[[i,0]] = 0
    end

    for i in 0..max_cost
      max_values[[0,i]] = 0
    end

    i = 0

    keepers.each do |player|
      i += 1

      for cost in 1..max_cost

        if player[cost_index] > cost
          max_values[[i,cost]] = max_values[[i-1,cost]]
          max_values_players[[i,cost]] = max_values_players[[i-1,cost]]
        else
          player_max = max_values[[i-1, cost-player[cost_index]]] + player[points_index]

          if player_max >= max_values[[i-1,cost]]
            max_values[[i,cost]] = player_max
            max_values_players[[i,cost]] = max_values_players[[i-1, cost-player[cost_index]]] + " " + player[name_index]
          else
            max_values[[i,cost]] = max_values[[i-1,cost]]
            max_values_players[[i,cost]] = max_values_players[[i-1,cost]]
          end
                
        end

      end
    end

    return max_values[[i,max_cost]], max_values_players[[i,max_cost]]
  end

  def predict_draft
    # run simdraft and predict keepers until no changes
    @simpicks = simulate_draft
    @keepers = predict_keepers(@simpicks)

    @keeper_points = []
    @keeper_players = []

    @keepers.each do |keeper|
      points, players = knapsack_keepers(keeper, 1532)
      @keeper_points.push(points)
      @keeper_players.push(players)
    end

    render 'simulate_draft'
  end

  def queue_players(players)
    qbs = []
    rbs = []
    wrs = []
    tes = []
    lbs = []
    dls = []
    dbs = []
    ks = []
    hcs = []

    players.each do |player|
      position = Player.find_by(:id => player.player_id).position

      if position == "QB"
        qbs.push(player)
      elsif position == "RB"
        rbs.push(player)
      elsif position == "WR"
        wrs.push(player)
      elsif position == "TE"
        tes.push(player)
      elsif position == "LB"
        lbs.push(player)
      elsif position == "DL"
        dls.push(player)
      elsif position == "DB"
        dbs.push(player)
      elsif position == "K"
        ks.push(player)
      else
        hcs.push(player)
      end
    end

    return qbs, rbs, wrs, tes, lbs, dls, dbs, ks, hcs

  end

  def find_team_by_pick_num(pick_number)
    ascending = true
    num_picks = 200
    pick_order = 1  
    round = 1

    pick_num = 1
      # change draft order

    while pick_num != pick_number

      pick_num += 1

      if ascending & (pick_order < 10)
        pick_order += 1
      elsif ascending
        ascending = false
        round += 1
      elsif !ascending & (pick_order > 1)
        pick_order -= 1
      else
        ascending = true
        round += 1
      end     
    end

    team = Team.find_by(:name => session[:draft_order][pick_order-1])

    trade = session[:draft_trades][[team,round]]

    if !trade.nil?
      team = Team.find_by(:name => trade)
    end

    return team, round

  end  

  def test_draft_trades(trades)
    traded = []
    nottraded = []

    trades.each do |trade|
      team1 = Team.find_by(:name => trade[0])
      team2 = Team.find_by(:name => trade[1])

      if !team1.nil?
        traded.push(team1.name)
      else 
        nottraded.push(trade[0])
      end

      if !team2.nil?
        traded.push(team2.name)
      else
        nottraded.push(trade[1])
      end

    end

    return traded, nottraded


  end

  def test_keepers(keepers)
    found = []
    notfound = []

    keepers.each do |keeper|
      player = Player.find_by(:name => keeper)
      if player.nil?
        notfound.push(keeper)
      else
        found.push(keeper)
      end
    end

    return found, notfound

  end  

  # GET /drafts/1
  # GET /drafts/1.json
  def show
  end

  # GET /drafts/new
  def new
    @draft = Draft.new
  end

  # GET /drafts/1/edit
  def edit
  end

  # POST /drafts
  # POST /drafts.json
  def create
    @draft = Draft.new(draft_params)

    respond_to do |format|
      if @draft.save
        format.html { redirect_to @draft, notice: 'Draft was successfully created.' }
        format.json { render action: 'show', status: :created, location: @draft }
      else
        format.html { render action: 'new' }
        format.json { render json: @draft.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /drafts/1
  # PATCH/PUT /drafts/1.json
  def update
    respond_to do |format|
      if @draft.update(draft_params)
        format.html { redirect_to @draft, notice: 'Draft was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @draft.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /drafts/1
  # DELETE /drafts/1.json
  def destroy
    @draft.destroy
    respond_to do |format|
      format.html { redirect_to drafts_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_draft
      @draft = Draft.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def draft_params
      params.permit(:name, :player)
    end
end
