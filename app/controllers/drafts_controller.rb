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

  def initialize_draft
    @round_draftees = []
    # intialize teams
    league = League.find_by(:name => "Speeding Utility Ram")
    @teams = Team.where(:league_id => league.id) 
    rounds = 20 
    @num_picks = @teams.count * rounds    


    #initialize array of picks
    @draft_order = ["Team 8 - JD", "Team 10 - Dan", "Team 6 - Josh", "Team 7 - Tony", "Team 5 - Mark", "Team 1 - Me", "Team 3 - Calen", "Team 9 - Brett", "Team 2 - Tim", "Team 4 - Matt"]        
    # @picks = Hash.new
    @picks = []

    # positions
    @num_starters = { "QB" => 1, "RB" => 2, "WR" => 2, "TE" => 1, "FLEX" => 1, "LB" => 1, "DL" => 1, "DB" => 1, "K" => 1, "HC" => 1 }
    @max_per_position = { "QB" => 2, "RB" => 5, "WR" => 5, "TE" => 2, "FLEX" => nil, "LB" => 3, "DL" => 4, "DB" => 4, "K" => 3, "HC" => 2, "BENCH" => 8, "IR" => 2 }    

    # initialize available players
    # queue players
    players = Recruit.order('projected_points desc')
    @qbs, @rbs, @wrs, @tes, @lbs, @dls, @dbs, @ks, @hcs = queue_players(players)    
    initialize_players_per_position(@teams, @num_starters)        

    @keepers = ["Drew Brees", "A.J. Green", "Victor Cruz", "Dez Bryant", "DeMarco Murray",
      "Michael Crabtree", "Matt Forte", "Calvin Johnson", "Jay Cutler", "Rashad Jennings", "Julius Thomas", 
      "Demaryius Thomas", "Rob Gronkowski", "Stephen Gostkowski", "Eddie Lacy", "Marshawn Lynch", "Jamaal Charles", "Greg Olsen",
      "Adrian Peterson", "Brandon Marshall", "Giovani Bernard", "Percy Harvin", "Jordan Cameron", "Peyton Manning", "Julio Jones",
      "LeSean McCoy", "Mike Wallace", "Colin Kaepernick", "Doug Martin", "Jimmy Graham", "Le'Veon Bell", "Zac Stacy", "Eagles Coach",
      "Aaron Rodgers", "Vernon Davis", "DeSean Jackson", "Alshon Jeffery", "Montee Ball"]    


    initialize_picks(@draft_order, "Snake", @keepers)    

    # test keepers entered correctly:
    # @found, @notfound = test_keepers(@keepers)

    # format [sending pick, receiving pick, round]
    @draft_trades = { ["Team 4 - Matt", 16] => "Team 2 - Tim", ["Team 2 - Tim", 7] => "Team 4 - Matt", ["Team 2 - Tim", 10] => "Team 4 - Matt", ["Team 8 - JD", 8] => "Team 1 - Me", ["Team 1 - Me", 13] => "Team 8 - JD" }

    # test draft trades entered correctly
    # @traded, @nottraded = test_draft_trades(@draft_trades)

    # redirect_to live_draft
    
    simulate_draft
  end

  def live_draft
    # #league, team info
    # league = League.find_by(:name => "Speeding Utility Ram")
    # teams = Team.where(:league_id => league.id)    
    # # queue players
    # players = Recruit.order('projected_points desc')
    # qbs, rbs, wrs, tes, lbs, dls, dbs, ks, hcs = queue_players(players)

    # positions
    # num_starters = { "QB" => 1, "RB" => 2, "WR" => 2, "TE" => 1, "FLEX" => 1, "LB" => 1, "DL" => 1, "DB" => 1, "K" => 1, "HC" => 1 }
    # max_per_position = { "QB" => 2, "RB" => 5, "WR" => 5, "TE" => 2, "FLEX" => nil, "LB" => 3, "DL" => 4, "DB" => 4, "K" => 3, "HC" => 2, "BENCH" => 8, "IR" => 2 }

    # draft_order = ["Team 8 - JD", "Team 10 - Dan", "Team 6 - Josh", "Team 7 - Tony", "Team 5 - Mark", "Team 1 - Me", "Team 3 - Calen", "Team 9 - Brett", "Team 2 - Tim", "Team 4 - Matt"]    

    # @keepers = ["Drew Brees", "A.J. Green", "Victor Cruz", "Dez Bryant", "Demarco Murray",
    #   "Michael Crabtree", "Matt Forte", "Calvin Johnson", "Jay Cutler", "Rashad Jennings", "Julius Thomas", 
    #   "Demaryius Thomas", "Rob Gronkowski", "Stephen Gostkowski", "Eddie Lacy", "Marshawn Lynch", "Jamaal Charles", "Greg Olsen",
    #   "Adrian Peterson", "Brandon Marshall", "Giovani Bernard", "Percy Harvin", "Jordan Cameron", "Peyton Manning", "Julio Jones",
    #   "LeSean McCoy", "Mike Wallace", "Colin Kaepernick", "Doug Martin", "Jimmy Graham", "Le'Veon Bell", "Zac Stacy", "Eagle Coach",
    #   "Aaron Rodgers", "Vernon Davis", "DeSean Jackson", "Alshon Jeffrey", "Montee Ball"]    

    # test keepers entered correctly:
    # @found, @notfound = test_keepers(@keepers)
    # @draft_trades = [["Team 4 - Matt", "Team 2 - Tim", 16], ["Team 2 - Tim", "Team 4 - Matt", 7], ["Team 2 - Tim", "Team 4 - Matt", 10], ["Team 8 - JD", "Team 1 - Me", 8], ["Team 1 - Me", "Team 8 - JD", 13]]

    # test draft trades entered correctly
    # @traded, @nottraded = test_draft_trades(@draft_trades)

  end

  def initialize_picks(draft_order, draft_type, keepers)
    if draft_type == "Snake"
      ascending = true
      num_picks = 200
      pick_order = 1  
      round = 1

      @keeper_picks = initialize_keeper_picks(keepers)

      for pick in 1..200

        index = pick_order - 1
        team = Team.find_by(:name => draft_order[index])        

        keeper = @keeper_picks[[round,team.id]]

        if !keeper.nil?
          # @picks[[pick,team.id]] = keeper.name
          @picks[pick] = [keeper.name, team.name]

          # update position counts
          player = Player.find_by(:name => keeper.name)
          position = player.position
          index = team.name + position
          # @num_players_per_position[index] += 1

          #remove player from available player queue
          remove_player_from_queue(player, team)
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

    # build out for other types of drafts
  end

  def remove_player_from_queue(player, team)
    recruit = Recruit.find_by(:player_id => player.id)

    # establish flexkey
    flexkey = team.name + "FLEX"

    if (@qbs.size > 0) && (player.position == "QB")
      @qbs.delete(recruit)
      key = team.name + "QB"
      @num_players_per_position[key] += 1

    elsif (@rbs.size > 0) && (player.position == "RB")
      @rbs.delete(recruit)
      key = team.name + "RB"
      num = @num_players_per_position[key]

      if ((num == @num_starters["RB"]) && (@num_players_per_position[flexkey] == 0))
        @num_players_per_position[flexkey] = 1
      end

      @num_players_per_position[key] += 1

    elsif (@wrs.size > 0) && (player.position == "WR")
      @wrs.delete(recruit)
      key = team.name + "WR"
      num = @num_players_per_position[key]

      if (num == @num_starters["WR"]) && (@num_players_per_position[flexkey] == 0)
        @num_players_per_position[flexkey] = 1
      end

      @num_players_per_position[key] += 1

    elsif (@tes.size > 0) && (player.position == "TE")
      @tes.delete(recruit)
      key = team.name + "TE"
      num = @num_players_per_position[key]

      if (num == @num_starters["TE"]) && (@num_players_per_position[flexkey] == 0)
        @num_players_per_position[flexkey] = 1
      end

      @num_players_per_position[key] += 1 

    elsif (@lbs.size > 0) && (player.position == "LB")
      @lbs.delete(recruit)
      key = team.name + "LB"
      @num_players_per_position[key] += 1

    elsif (@dbs.size > 0) && (player.position == "DB")
      @dbs.delete(recruit)   
      key = team.name + "DB"
      @num_players_per_position[key] += 1

    elsif (@dls.size > 0) && (player.position == "DL")
      @dls.delete(recruit)
      key = team.name + "DL"
      @num_players_per_position[key] += 1     

    elsif (@ks.size > 0) && (player.position == "K")
      @ks.delete(recruit)
      key = team.name + "K"
      @num_players_per_position[key] += 1

    elsif (@hcs.size > 0) && (player.position == "HC")
      @hcs.delete(recruit)
      key = team.name + "HC"
      @num_players_per_position[key] += 1     
    end

  end

  def initialize_keeper_picks(keepers)
    keeper_picks = Hash.new

    keepers.each do |keeper|
      player_info = Player.find_by(:name => keeper)
      position = player_info.position
      player_name = player_info.name
      pick = Pick.find_by(:player_id => player_info.id) 
      team = Recruit.find_by(:player_id => player_info.id).team_id

      if pick.nil?
        round = 20
      else
        round = (pick.round + 1)
      end   

      keeper_picks[[round,team]] = player_info

    end

    return keeper_picks

  end

  def initialize_players_per_position(teams, positions)
    @num_players_per_position = Hash.new(0)

    teams.each do |team|
      positions.each do |position, num|
        string = team.name + position

        @num_players_per_position[string] = 0
      end
    end    

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

  def simulate_draft
    # league = League.find_by(:name => "Speeding Utility Ram")
    # teams = Team.where(:league_id => league.id)
    # rounds = 20

    # players = Recruit.order('projected_points desc')

    # qbs, rbs, wrs, tes, lbs, dls, dbs, ks, hcs = queue_players(players)


    # num_starters = { "QB" => 1, "RB" => 2, "WR" => 2, "TE" => 1, "FLEX" => 1, "LB" => 1, "DL" => 1, "DB" => 1, "K" => 1, "HC" => 1 }
    # max_per_position = { "QB" => 2, "RB" => 4, "WR" => 4, "TE" => 2, "FLEX" => nil, "LB" => 3, "DL" => 4, "DB" => 4, "K" => 3, "HC" => 2, "BENCH" => 8, "IR" => 2 }

    # draft_order = ["Team 8 - JD", "Team 10 - Dan", "Team 6 - Josh", "Team 7 - Tony", "Team 5 - Mark", "Team 1 - Me", "Team 3 - Calen", "Team 9 - Brett", "Team 2 - Tim", "Team 4 - Matt"]

    # # initialize players per position on each team
    # @num_players_per_position = Hash.new(0)

    # teams.each do |team|
    #   num_starters.each do |position, num|
    #     string = team.name + position

    #     @num_players_per_position[string] = 0
    #   end
    # end

    ascending = true
    pick_order = 1
    round = 1

    @is_keepers = []
    @is_trades = []


    for pick in 1..@num_picks
      index = pick_order - 1
      team = Team.find_by(:name => @draft_order[index])

      trade = @draft_trades[[team.name,round]]

      if !trade.nil?
        team = Team.find_by(:name => trade)
        @is_trades[pick] = true
      else
        @is_trades[pick] = false
      end

      # is_keeper = @picks[[pick,team.id]]
      is_keeper = @picks[pick]

      if is_keeper == nil   #not a keeper chosen
        @is_keepers[pick] = false

        max = 0
        max_player = nil

        draftees = [@qbs.first, @rbs.first, @wrs.first, @tes.first, @lbs.first, @dls.first, @dbs.first, @ks.first, @hcs.first]

        # for debugging
        @round_draftees.push(draftees)

        draftees.each do |position|
          draftee = position

          if !draftee.nil?
            draftee = Player.find_by(:id => draftee.player_id)
            position = draftee.position

            @key = team.name + position
            @flexkey = team.name + "FLEX"
            @num_players_in_position = @num_players_per_position[@key]

            if @num_players_in_position < @num_starters[position]
              @mult = 1
            elsif ((@num_players_in_position == @num_starters[position]) && (position == "RB" || position == "WR" || position == "TE") && (@num_players_per_position[@flexkey] == 0))
              @mult = 1
            elsif @num_players_in_position < @max_per_position[position]
              @mult = (@num_starters[position].to_f / 16).to_f
            else
              @mult = 0
            end

            # need to consider FLEX position

            points = Recruit.find_by(:player_id => draftee.id).projected_points
            mult_points = (points.to_f * @mult).to_f

            if (mult_points) > max
              max = mult_points
              @projected = points
              max_player = draftee
              @number_picked = @num_players_per_position[team.name + draftee.position] + 1
            end
          end
        end

        if !max_player.nil?
          # player_data = [pick, max_player.name, max_player.position, team.name,  max, @number_picked, used_flex]
          # @picks[[pick,team.id]]= max_player.name
          @picks[pick] = [max_player.name,team.name]
          remove_player_from_queue(max_player, team)
        end        

      else
        @is_keepers[pick] = true
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

        # if player[cost_index] > cost
        #   if max_values[[i-1,cost]] >= max_values[[i,cost-1]]
        #     max_values[[i,cost]] = max_values[[i-1,cost]]
        #     max_values_players[[i,cost]] = max_values_players[[i-1,cost]]
        #   else
        #     max_values[[i,cost]] = max_values[[i,cost-1]]
        #     max_values_players[[i,cost]] = max_values_players[[i,cost-1]]
        #   end
        # else
        #   player_max = max_values[[i, cost-player[cost_index]]] + player[points_index]

        #   if (player_max >= max_values[[i-1,cost]]) && (player_max >= max_values[[i,cost-1]]) && !(max_values_players[[i,cost-player[cost_index]]].include?(player[name_index]))
        #     max_values[[i,cost]] = player_max
        #     max_values_players[[i,cost]] = max_values_players[[i, cost-player[cost_index]]] + " " + player[name_index]
        #   elsif (max_values[[i-1,cost]] >= player_max) && (max_values[[i-1,cost]] >= max_values[[i,cost-1]])
        #     max_values[[i,cost]] = max_values[[i-1,cost]]
        #     max_values_players[[i,cost]] = max_values_players[[i-1,cost]]
        #   else
        #     max_values[[i,cost]] = max_values[[i,cost-1]]
        #     max_values_players[[i,cost]] = max_values_players[[i,cost-1]]
        #   end
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
      params.require(:draft).permit(:name)
    end
end
