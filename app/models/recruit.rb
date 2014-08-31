class Recruit < ActiveRecord::Base

	belongs_to :player
	belongs_to :team
	has_many :players, dependent: :destroy


end
