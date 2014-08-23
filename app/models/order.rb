class Order < ActiveRecord::Base

	belongs_to :draft
	has_one :team
end
