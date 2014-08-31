class Draft < ActiveRecord::Base

	belongs_to :league
	has_many :orders, dependent: :destroy
	has_many :picks, dependent: :destroy
	has_many :players, through: :picks
end
