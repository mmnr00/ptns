class Payslip < ApplicationRecord
	belongs_to :taska
	belongs_to :teacher
	#serialize :xtra,String
end
