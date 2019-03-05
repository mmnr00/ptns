class Payment < ApplicationRecord
	belongs_to :parent, optional: true
	belongs_to :taska, optional: true
	belongs_to :teacher, optional: true
	belongs_to :course, optional: true
	has_many :kid_bills
	has_many :kids, through: :kid_bills
	has_many :addtns
	has_one :tskbill
	has_one :foto
	accepts_nested_attributes_for :addtns
	include HTTParty

	


end
