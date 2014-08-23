class Play < ActiveRecord::Base

	has_one :position
	has_one :player

	# if not using position table, this is not necessary

end
