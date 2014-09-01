class Recruit < ActiveRecord::Base

	validates :player_id, uniqueness: { scope: :league_id }

	belongs_to :player
	belongs_to :team
	has_many :players


end
