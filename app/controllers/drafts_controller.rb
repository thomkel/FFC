class DraftsController < ApplicationController
  before_action :set_draft, only: [:show, :edit, :update, :destroy]

  # GET /drafts
  # GET /drafts.json
  def index
    @drafts = Draft.all
  end

  def keepers
    @keepers = Recruit.where(:league_id => session[:league_id]).where('last_year_points > 0')
  end

  def add_pick  

    player_name = params[:player]
    player_like = "%#{player_name}%"
    @players_found = Player.where("lower(name) LIKE ?", player_like.downcase)

    if @players_found.size == 1
      player = @players_found.first

      testpick = Pick.where(:draft_id => session[:draft_id]).find_by(:player_id => player.id)

      if testpick.nil?      
        team, round = find_team_by_pick_num(session[:pick_number])
        team = Team.find_by(:name => team)

        pick = Pick.new
        pick.draft_id = session[:draft_id]
        pick.pick_num = session[:pick_number]
        pick.team_id = team.id
        pick.player_id = player.id
        pick.round = round
        pick.save      

        session[:pick_number] += 1

        @message = "Player Found"
      else
        @message = "Player already drafted in this draft!"
      end
      #elsif need errors
    elsif @players_found.size == 0
      @message = "No Players Found"
    elsif @players_found.size > 1
      @message = "More than one player found" 

      @players_found.each do |player|
        @message = @message + "||||||" + player.name.to_s
      end
    end

    @picks = Pick.where(:draft_id => session[:draft_id])            

    while (session[:pick_number] <= 200) && (!@picks.find_by(:pick_num => session[:pick_number]).nil?)
      session[:pick_number] += 1
    end    

    initialize_simulation(session[:draft_id], @picks)    

  end

  def initialize_draft
    # intialize teams
    
    # league = League.find_by(:name => "Speeding Utility Ram")
    league = League.find_by(:name => "CDW-Symantec League")
    session[:league_id] = league.id
    @teams = Team.where(:league_id => league.id) 
    session[:num_teams] = @teams.size
    # rounds = 20 
    session[:rounds] = 14
    # session[:myteam] = "Team 1 - Me"
    session[:myteam] = "Phil Syms"
    session[:num_picks] = @teams.count * session[:rounds]
    session[:pick_number] = 1

    olddraft = Draft.find_by(:name => "CDW-Symantec Draft")

    if !olddraft.nil?
      Pick.where(:draft_id => olddraft.id).destroy_all
      olddraft.destroy
    end

    # draft = Draft.new
    # draft.name = "Speeding Utility 2014"
    # draft.draft_type = "Snake"
    # draft.league_id = league.id
    # draft.num_rounds = 20
    # draft.save

    draft = Draft.new
    draft.name = "CDW-Symantec Draft"
    draft.draft_type = "Snake"
    draft.league_id = league.id
    draft.num_rounds = 20
    draft.save


    session[:draft_id] = draft.id

    #initialize array of picks
    session[:draft_order] = ["Sarcastic Smackdown", "West Coast Offense", "Riskes Business", "Phil Syms", "Pam Ashleys Team", "Authorized to Win", "The Finkanators", "Lindas Frozen Turndr", "GIN is the Answer",  "cs Marvelous Team",   "Holmes Skillet", "BigGreen Machine", "Cool Story Bro",  "Jimmy V",  "LeaD Em On", "Mean Machine"]        
    # session[:draft_trades] = { ["Team 4 - Matt", 16] => "Team 2 - Tim", ["Team 2 - Tim", 7] => "Team 4 - Matt", ["Team 2 - Tim", 10] => "Team 4 - Matt", ["Team 8 - JD", 8] => "Team 1 - Me", ["Team 1 - Me", 13] => "Team 8 - JD" }
    session[:draft_trades] = {}
    # positions
    # session[:num_starters] = { "QB" => 1, "RB" => 2, "WR" => 2, "TE" => 1, "FLEX" => 1, "LB" => 1, "DL" => 1, "DB" => 1, "K" => 1, "HC" => 1 }
    # session[:max_per_position] = { "QB" => 2, "RB" => 5, "WR" => 5, "TE" => 2, "FLEX" => nil, "LB" => 3, "DL" => 4, "DB" => 4, "K" => 3, "HC" => 2, "BENCH" => 8, "IR" => 2 }    
    session[:num_starters] = { "QB" => 1, "RB" => 2, "WR" => 2, "TE" => 1, "FLEX" => 1, "K" => 1, "DEF" => 1 }
    session[:max_per_position] = { "QB" => 5, "RB" => 5, "WR" => 5, "TE" => 5, "FLEX" => nil, "K" => 3, "DEF" => 3, "BENCH" => 5 }


    # initialize available players
    # queue players
    players = Recruit.where(:league_id => session[:league_id]).order('projected_points desc')
    # @qbs, @rbs, @wrs, @tes, @lbs, @dls, @dbs, @ks, @hcs = queue_players(players)    
    # queues = { "QB" => @qbs, "RB" => @rbs, "WR" => @wrs, "TE" => @tes, "LB" => @lbs, "DL" => @dls, "DB" => @dbs, "K" => @ks, "HC" => @hcs }
    # @qbs, @rbs, @wrs, @tes, @ks, @defs = queue_players(players)    
    @queues = queue_players(players) #{ "QB" => @qbs, "RB" => @rbs, "WR" => @wrs, "TE" => @tes, "K" => @ks, "DEF" => @defs }

    @num_players_per_position = initialize_players_per_position(@teams, session[:num_starters])        

    # @keepers = ["Drew Brees", "A.J. Green", "Victor Cruz", "Dez Bryant", "DeMarco Murray",
    #   "Michael Crabtree", "Matt Forte", "Calvin Johnson", "Jay Cutler", "Rashad Jennings", "Julius Thomas", 
    #   "Demaryius Thomas", "Rob Gronkowski", "Stephen Gostkowski", "Eddie Lacy", "Marshawn Lynch", "Jamaal Charles", "Greg Olsen",
    #   "Adrian Peterson", "Brandon Marshall", "Giovani Bernard", "Percy Harvin", "Jordan Cameron", "Peyton Manning", "Julio Jones",
    #   "LeSean McCoy", "Mike Wallace", "Colin Kaepernick", "Doug Martin", "Jimmy Graham", "Le'Veon Bell", "Zac Stacy", "Eagles Coach",
    #   "Aaron Rodgers", "Vernon Davis", "DeSean Jackson", "Alshon Jeffery", "Montee Ball"]    

    @keepers = []

    initialize_picks(session[:draft_order], draft.draft_type, @keepers, @queues, @num_players_per_position)    

    @picks = Pick.where(:draft_id => session[:draft_id])

    initialize_simulation(draft.id, @picks)

  end

  def initialize_picks(draft_order, draft_type, keepers, queues, players_per_position)
    if draft_type == "Snake" 
      ascending = true
      pick_order = 1  
      round = 1

      @keeper_picks = initialize_keeper_picks(keepers)

      for pick in 1..session[:num_picks]

        index = pick_order - 1
        team = draft_order[index]

        keeper = @keeper_picks[[round,team]]

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
          remove_player_from_queue(keeper.name, draft_order[index], queues, players_per_position)
        end

        # change draft order
        if ascending & (pick_order < session[:num_teams])
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

  def remove_player_from_queue(player, position, team, queues, players_per_position)

    # establish flexkey
    key = team + position
    flexkey = team + "FLEX"

    queues[position].delete(player)

    # check if need to update flex
    if (position == "RB" || position == "WR" || position == "TE") 
      num = players_per_position[key]

      if ((num == session[:num_starters][position]) && (players_per_position[flexkey] == 0))
        players_per_position[flexkey] = 1
      end
    end

    players_per_position[key] += 1
 
  end

  def initialize_keeper_picks(keepers)
    keeper_picks = Hash.new

    keepers.each do |keeper|
      player_info = Player.find_by(:name => keeper)
      position = player_info.position
      player_name = player_info.name
      pick = Pick.find_by(:player_id => player_info.id) 
      recruit = Recruit.where(:league_id => session[:league_id]).find_by(:player_id => player_info.id)
      team = Team.find_by(:id => recruit.team_id).name

      if (pick.nil?) || (pick.round == session[:rounds])
        round = session[:rounds]
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

  def initialize_simulation(draft_id, picks)
    # picks = Pick.where(:draft_id => draft_id)
    #need to make league specific
    players = Recruit.where(:league_id => session[:league_id]).order('projected_points desc') 

    # sim_qbs, sim_rbs, sim_wrs, sim_tes, sim_lbs, sim_dls, sim_dbs, sim_ks, sim_hcs = queue_players(players)
    # s_qbs, s_rbs, s_wrs, s_tes, s_lbs, s_dls, s_dbs, s_ks, s_hcs = queue_players(players)
    # sim_qbs, sim_rbs, sim_wrs, sim_tes, sim_ks, sim_dsts = queue_players(players)
    # s_qbs, s_rbs, s_wrs, s_tes, s_ks, s_dsts = queue_players(players)


    # queues = { "QB" => sim_qbs, "RB" => sim_rbs, "WR" => sim_wrs, "TE" => sim_tes, "LB" => sim_lbs, "DL" => sim_dls, "DB" => sim_dbs, "K" => sim_ks, "HC" => sim_hcs }
    # s_queues = { "QB" => s_qbs, "RB" => s_rbs, "WR" => s_wrs, "TE" => s_tes, "LB" => s_lbs, "DL" => s_dls, "DB" => s_dbs, "K" => s_ks, "HC" => s_hcs }

    @queues = queue_players(players) #{ "QB" => sim_qbs, "RB" => sim_rbs, "WR" => sim_wrs, "TE" => sim_tes, "K" => sim_ks, "DEF" => sim_dsts }


    league_id = Draft.find_by(:id => session[:draft_id]).league_id
    # sim_num_players_per_position = initialize_players_per_position(Team.where(:league_id => league_id), session[:num_starters])        
    sim_players_per_position = initialize_players_per_position(Team.where(:league_id => league_id), session[:num_starters])        

    @drafted_picks = []
    # sim_players_per_position = []
    # s_players = []

    picks.each do |pick|
      pick_num = pick.pick_num
      player = Player.find_by(:id => pick.player_id)
      team = Team.find_by(:id => pick.team_id)

      player_data = [player.name, Recruit.where(:league_id => session[:league_id]).find_by(:player_id => player.id).projected_points]


      @drafted_picks[pick_num] = [player.name, player.position, team.name]
      remove_player_from_queue(player_data, player.position, team.name, @queues, sim_players_per_position)        

    end 

    sim_queues = copy_hash(@queues)  
    s_queues = copy_hash(@queues)   
    s_players = sim_players_per_position.clone

    sim_drafted = Array.new(@drafted_picks)
    s_picked = Array.new(@drafted_picks)

    @sim_picks = simulate_draft(sim_drafted, sim_queues, sim_players_per_position, nil)    

    @suggest_value, @suggest_picks = suggest_picks(s_picked, @sim_picks, s_queues, s_players, session[:pick_number])

    render 'initialize_draft'         

  end

  def simulate_draft(picks, queues, players_per_position, endpick)

    lastpick = endpick

    if lastpick.nil?
      lastpick = session[:num_picks]
    end

    ascending = true
    pick_order = 1
    round = 1

    for pick in 1..lastpick
      index = pick_order - 1
      team = session[:draft_order][index]

      trade = session[:draft_trades][[team,round]]

      if !trade.nil?
        team = trade
      end

      is_keeper = picks[pick]

      if is_keeper == nil   #not a keeper chosen

        max = 0
        max_player = nil
        max_position = nil
        draftee = nil

        queues.each do |position, players|
          draftee = players[0]

          if !draftee.nil?
            points = draftee[1]
            mult_points = calc_points(points, players_per_position, team, position)

            if (mult_points) > max
              max = mult_points
              projected = points
              max_player = draftee
              max_position = position
            end
          end
        end

        if !max_player.nil?
          picks[pick] = [max_player[0], max_position, team]
          remove_player_from_queue(max_player, max_position, team, queues, players_per_position)
        end        

      end

      # change draft order
      if ascending & (pick_order < session[:num_teams])
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

    return picks

  end

# s_drafted, Array.new(@sim_picks), s_queues, s_players, session[:pick_number]

  def suggest_picks(picked, simpicks, queues, players_per_position, pick_num)

    team, round = find_team_by_pick_num(pick_num)  

    if team == session[:myteam]

      max_value, max_players = sum_player_values(picked, simpicks, queues, players_per_position, pick_num, 0)

      return max_value, max_players

    else
      return nil, nil
    end

  end

  def sum_player_values(picked, simpicks, queues, players_per_position, pick_num, iterations)
    if pick_num < session[:num_picks] && iterations < 5

      max_value_new = 0
      max_players_new = []

      nextpick = find_teams_next_pick(pick_num, session[:myteam])

      if !picked[pick_num].nil?  # is a keeper
        draft_value, draft_players = sum_player_values(picked, simpicks, queues, players_per_position, nextpick, iterations)

        max_value_new = draft_value
        max_players_new = draft_players.unshift("KEEPER: " + picked[pick_num][0] + pick_num.to_s) 

      else

        positions_picked = predict_positions_picked(pick_num, nextpick, picked, queues, players_per_position)  

        positions_picked.each do |position|
          @sim_queues = copy_hash(queues)
          sim_picked = Array.new(picked)
          sim_players = players_per_position.clone
          suggest_drafted = Array.new(simpicks)

          recruit = @sim_queues[position][0]
          player_points = calc_points(recruit[1], sim_players, session[:myteam], position)

          # update
          # player = Player.find_by(:id => recruit.player_id)
          # team = Team.find_by(:name => session[:myteam])

          remove_player_from_queue(recruit, position, session[:myteam], @sim_queues, sim_players)
          suggest_drafted[pick_num] = [recruit[0], recruit[1], session[:myteam]]

          # sim_picks = simulate_draft(Array.new(suggest_drafted), copy_hash(suggest_queues), suggest_players.clone, nextpick)       
          sim_picks = simulate_draft(sim_picked, @sim_queues, sim_players, nextpick-1) 

           # redundant? taking out suggest_drafted... just using sim_picks

          # for pick in pick_num+1..nextpick-1
          #   suggest_drafted[pick] = sim_picks[pick]

          #   redundant-- already completed in simulate draft

          #   if suggest_queues[simplayer.position].include?(Recruit.where(:league_id => session[:league_id]).find_by(:player_id => simplayer.id))
          #     suggest_queues, suggest_players = remove_player_from_queue(simplayer, simteam, suggest_queues, suggest_players)

          #   end
          # end


          draft_value, draft_players = sum_player_values(sim_picked, sim_picks, @sim_queues, sim_players, nextpick, iterations+1)

          total_value = player_points + draft_value

          if total_value > max_value_new
            max_value_new = total_value
            max_players_new = draft_players.unshift(recruit[0] + pick_num.to_s)
          end

        end
      end
      
      return max_value_new, max_players_new      

    else
      return 0, []
    end    

  end

  def find_teams_next_pick(picknum, team)
    
    nextpick = picknum + 1

    nextteam, round = find_team_by_pick_num(nextpick)

    while (nextteam != team) && (nextpick < session[:num_picks])
      nextpick += 1
      nextteam, round = find_team_by_pick_num(nextpick)
    end

    return nextpick

  end

  def predict_positions_picked(pick, nextpick, picks, queues, players_per_position)

    sim_picked = Array.new(picks)
    sim_queues = copy_hash(queues)
    sim_players = players_per_position.clone

    simpicks = simulate_draft(sim_picked, sim_queues, sim_players, nextpick) 

    positions_picked = []

    while pick < nextpick

      pick += 1

      position = simpicks[pick][1]

      if !positions_picked.include?(position)
        positions_picked.push(position)
      end

    end

    return positions_picked

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
              comp_points = Recruit.where(:league_id => session[:league_id]).find_by(:player_id => comp_player_id).projected_points
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

  def copy_hash(hash)
    newhash = Hash.new

    hash.each do |key, values|
      newhash[key] = Array.new(values)
    end

    return newhash

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
    # qbs = []
    # rbs = []
    # wrs = []
    # tes = []
    # # lbs = []
    # # dls = []
    # # dbs = []
    # ks = []
    # # hcs = []
    # dsts = []

    positions = Hash.new {|h,k| h[k] = Array.new }

    # players.each do |playa|
    #   position = playa.player.position

    #   if position == "QB"
    #     qbs.push(player)
    #   elsif position == "RB"
    #     rbs.push(player)
    #   elsif position == "WR"
    #     wrs.push(player)
    #   elsif position == "TE"
    #     tes.push(player)
    #   # elsif position == "LB"
    #   #   lbs.push(player)
    #   # elsif position == "DL"
    #   #   dls.push(player)
    #   # elsif position == "DB"
    #   #   dbs.push(player)
    #   elsif position == "K"
    #     ks.push(player)
    #   else
    #     # hcs.push(player)
    #     dsts.push(player)
    #   end
    # end

    players.each do |recruit|

      player_data = [recruit.player.name, recruit.projected_points]

      players_array = positions[recruit.player.position]

      players_array.push(player_data)

    end

    # return qbs, rbs, wrs, tes, lbs, dls, dbs, ks, hcs
    # return qbs, rbs, wrs, tes, ks, dsts
    return positions


  end

  def find_team_by_pick_num(pick_number)
    ascending = true
    num_picks = session[:num_picks]
    pick_order = 1  
    round = 1

    pick_num = 1
      # change draft order

    while pick_num != pick_number

      pick_num += 1

      if ascending & (pick_order < session[:num_teams])
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

    team = session[:draft_order][pick_order-1]

    trade = session[:draft_trades][[team,round]]

    if !trade.nil?
      team = trade
    end

    return team, round

  end  

  def calc_points(points, players_per_position, team, position)
    key = team + position
    flexkey = team + "FLEX"
    num_players_in_position = players_per_position[key]
    flex_used = players_per_position[flexkey]

    if num_players_in_position < session[:num_starters][position]
      mult = 1
    elsif ((num_players_in_position == session[:num_starters][position]) && (position == "RB" || position == "WR" || position == "TE") && (flex_used == 0))
      mult = 1
    elsif num_players_in_position < session[:max_per_position][position]
      mult = (session[:num_starters][position].to_f / 16).to_f
    else
      mult = 0
    end

    mult_points = (points.to_f * mult).to_f    

    return mult_points
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
