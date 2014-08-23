class Pick < ActiveRecord::Base

	belongs_to :draft
	has_one :team
	has_one :player
end
