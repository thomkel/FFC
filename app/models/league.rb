class League < ActiveRecord::Base

	has_many :teams, dependent: :destroy
	has_many :drafts, dependent: :destroy
	has_many :recruits, through: :teams, dependent: :destroy
end
