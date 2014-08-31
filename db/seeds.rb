# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# require 'open-uri'
# require 'nokogiri'
# require 'mechanize'

# seed league and teams

# league_page = Nokogiri::HTML(open("http://games.espn.go.com/ffl/welcome/gotoleague?leagueId=107998&seasonId=2014"))

# teams = league_page.css("tr.ownerRow")

# teams.each do |team|
# 	# team = team.css("td.teamName")
# 	puts team
# end

# testing mechanize to automate leauge-specific data finding

# agent = Mechanize.new
# page = agent.get("http://games.espn.go.com/ffl/welcome/gotoleague?leagueId=107998&seasonId=2014")

# form = page.forms.third
# form.username = "thomjkelly"
# password
# # form.add_field! 'submit','Sign In'
# # form.submit
# page2 = form.submit( form.button_with(:value => "Sign In") )


# seed players-- neutral, not league specific

# Player.destroy_all

# qb_page = Nokogiri::HTML(open("http://games.espn.go.com/ffl/tools/projections?&slotCategoryId=0"))

# #qbs = qb_page.css("td.playertablePlayerName")
# qbs = qb_page.css("tr.pncPlayerRow")

# qbs.each do |qb|

# 	player_row = qb.css("td.playertablePlayerName")
# 	player_tag = qb.css("td.playertablePlayerName a")

# 	#player name
# 	name = player_tag.text
# 	puts name

# 	#position
# 	position = player_row.text.split(/[[:space:]]/)
# 	puts position[3]

# 	#image_url
# 	playerid = player_tag[0]["playerid"] #insert playerid into url below to get player photo
# 	link = "http://a.espncdn.com/combiner/i?img=/i/headshots/nfl/players/full/#{playerid}.png&w=200&h=145&scale=crop&background=0xcccccc&transparent=false"
# 	puts link
# end


# running out of time before season starts-- new route

League.destroy_all

league = League.new
league.name = "Speeding Utility Ram"
league.save

Player.destroy_all
Recruit.destroy_all

sheets = ["qbs", "rbs", "wrs", "tes", "lbs", "dls", "dbs", "ks", "hcs"]

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

sheets.each do |sheet|
	CSV.foreach(File.path("db/#{sheet}.csv")) do |player|
		if !player[0].nil?
			player_data = player[0].split(",")
			player_name = player_data[0].gsub("*", "")
			player_data = player_data[1].split(/[[:space:]]/)

			player_position = player_data[2]

			player_points = player[1]

			new_player = Player.new
			new_player.name = player_name
			new_player.position = standardize_position(player_position)
			new_player.save

			puts "New player: " + new_player.name

			new_player_id = new_player.id

			recruit = Recruit.new
			recruit.player_id = new_player_id
			recruit.projected_points = player_points
			recruit.league_id = league.id
			recruit.save

			puts "\tNew recruit: " + recruit.player_id.to_s + ", " + recruit.projected_points.to_s

		end
	end
end


Demand.destroy_all

num_starters = { "QB" => 1, "RB" => 2, "WR" => 2, "TE" => 1, "FLEX" => 1, "LB" => 1, "DL" => 1, "DB" => 1, "K" => 1, "HC" => 1 }
max_per_position = { "QB" => 2, "RB" => 4, "WR" => 4, "TE" => 2, "FLEX" => nil, "LB" => 3, "DL" => 4, "DB" => 4, "K" => 3, "HC" => 2, "BENCH" => 8, "IR" => 2 }

max_per_position.each do |position, num| 
	demand = Demand.new
	demand.league_id = league.id
	demand.position = position
	demand.max_per_position = num
	demand.num_starters = num_starters[position]
	demand.save

	puts "New demand: league-" + demand.league_id.to_s + " position-" + demand.position + " starters " + demand.num_starters.to_s + " max- " +demand.max_per_position.to_s
end

Team.destroy_all

sheets = ["Team 1 - Me", "Team 2 - Tim", "Team 3 - Calen", "Team 4 - Matt", "Team 5 - Mark", "Team 6 - Josh", "Team 7 - Tony", "Team 8 - JD", "Team 9 - Brett", "Team 10 - Dan"]

sheets.each do |sheet|

	team = Team.new
	team.name = sheet
	team.league_id = league.id
	team.save

	puts "New team: " + sheet

	CSV.foreach(File.path("db/#{sheet}.csv")) do |player|
		if !player[0].nil?
			player_data = player[0].split(",")
			player_name = player_data[0].gsub("*", "")

			player_found = Player.find_by(:name => player_name)

			if player_found.nil?
				new_player = Player.new
				new_player.name = player_name

				if player_data.size == 1
					new_player.position = "HC"
				else
					player_data = player_data[1].split(/[[:space:]]/)
					new_player.position = standardize_position(player_data[2])
				end

				new_player.save

				puts "New player: " + new_player.name
			else
				puts player_found.name + " found"
				recruit = Recruit.find_by(:player_id => player_found.id)
				recruit.last_year_points = player[1]
				recruit.team_id = team.id
				recruit.save

				puts "Updated recruits data-- last year points: " + recruit.last_year_points.to_s + ", projected: " + recruit.projected_points.to_s
				puts "\tPlaying for " + team.name
			end

		end
	end
end


draft = Draft.new
draft.name = "2013 Speeding Utility Draft"
draft.draft_type = "snake"
draft.num_rounds = 20
draft.league_id = league.id
draft.save

num_teams = Team.where(:league_id => league.id).count

pick_num = 1

CSV.foreach(File.path("db/2013 Speeding Utility Draft.csv")) do |pick|
	pick = pick.to_s.split("-")
	player_data = pick[1].split(" ")

	player = ""
	count = 0

	size = player_data.size

	while count < (size - 1)
		player += player_data[count].to_s + " "
		count = count + 1
	end

	player = player.strip

	player_found = Player.find_by(:name => player)

	if player_found.nil?
		new_player = Player.new
		new_player.name = player
		position = player_data[count].to_s
		puts position
		position = position.strip
		position = position.gsub('"', "")
		position = position.gsub("]", "")
		position = standardize_position(position)
		new_player.position = position
		new_player.save

		puts "New player created: name- " + new_player.name + ", position- " + new_player.position + "//////////////////////////"

		player_found = new_player
	end

	new_pick = Pick.new
	new_pick.draft_id = draft.id
	new_pick.pick_num = pick_num
	new_pick.player_id = player_found.id
	new_pick.round = (((pick_num - 1) / num_teams) + 1).to_i
	new_pick.save

	puts "Created new pick: pick: " + new_pick.pick_num.to_s + ", round: " + new_pick.round.to_s + ", player: " + player_found.name + ", draft_id: " + new_pick.draft_id.to_s

	pick_num += 1

end	

league = League.new
league.name = "CDW-Symantec League"
league.save

Demand.destroy_all

num_starters = { "QB" => 1, "RB" => 2, "WR" => 2, "TE" => 1, "FLEX" => 1, "K" => 1, "DEF" => 1 }
max_per_position = { "QB" => 5, "RB" => 5, "WR" => 5, "TE" => 5, "FLEX" => nil, "K" => 3, "BENCH" => 5 }

max_per_position.each do |position, num| 
	demand = Demand.new
	demand.league_id = league.id
	demand.position = position
	demand.max_per_position = num
	demand.num_starters = num_starters[position]
	demand.save

	puts "New demand: league-" + demand.league_id.to_s + " position-" + demand.position + " starters " + demand.num_starters.to_s + " max- " +demand.max_per_position.to_s
end


sheets = ["sym_qbs", "sym_rbs", "sym_wrs", "sym_tes", "sym_ks", "sym_dsts"]

sheets.each do |sheet|
	CSV.foreach(File.path("db/#{sheet}.csv")) do |player|
		if !player[0].nil?
			player_data = player[0].split(",")
			player_name = player_data[0].gsub("*", "")
			player_data = player_data[1].split(/[[:space:]]/)

			player_position = player_data[2]

			player_points = player[1]

			found_player= Player.find_by(:name => player_name)
			new_player_id = nil

			if found_player.nil?

				new_player = Player.new
				new_player.name = player_name
				new_player.position = standardize_position(player_position)
				new_player.save

				puts "New player: " + new_player.name

				new_player_id = new_player.id

			else
				new_player_id = found_player.id
			end

			recruit = Recruit.new
			recruit.player_id = new_player_id
			recruit.projected_points = player_points
			recruit.league_id = league.id
			recruit.save

			puts "\tNew recruit: " + recruit.player_id.to_s + ", " + recruit.projected_points.to_s

		end
	end
end

sheets = ["Cool Story Bro", "Riskes Business", "Mean Machine", "Phil Syms", "cs Marvelous Team", "Authorized to Win", "BigGreen Machine", "GIN is the Answer", "LeaD Em On", "The Finkanators", "Lindas Frozen Turndr", "Pam Ashleys Team", "West Coast Offense", "Holmes Skillet", "Jimmy V", "Sarcastic Smackdown"]

sheets.each do |sheet|

	team = Team.new
	team.name = sheet
	team.league_id = league.id
	team.save	

end
