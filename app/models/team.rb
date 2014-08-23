class Team < ActiveRecord::Base

	belongs_to :league
	has_many :recruits
	has_many :players, through: :recruits
end
