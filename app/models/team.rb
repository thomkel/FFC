class Team < ActiveRecord::Base

	belongs_to :league
	has_many :recruits, dependent: :destroy
	has_many :players, through: :recruits
end
