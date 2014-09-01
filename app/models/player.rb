class Player < ActiveRecord::Base

	validates :name, :presence=>true, :uniqueness=>true	
	has_many :recruits, dependent: :destroy
end
