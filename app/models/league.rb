class League < ActiveRecord::Base
	validates :name, :presence=>true, :uniqueness=>true	

	has_many :teams, dependent: :destroy
	has_many :drafts, dependent: :destroy
	has_many :recruits, through: :teams, dependent: :destroy
end
