class Franchise < ActiveRecord::Base

	has_one :team
	has_one :league
end
