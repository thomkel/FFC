class Play < ActiveRecord::Base

	has_one :position
	has_one :player

end
