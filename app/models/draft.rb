class Draft < ActiveRecord::Base

	belongs_to :league
	has_many :orders
	has_many :picks
	has_many :players, through: :picks
end
