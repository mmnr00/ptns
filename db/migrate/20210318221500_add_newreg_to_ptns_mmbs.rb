class AddNewregToPtnsMmbs < ActiveRecord::Migration[5.2]
  def change
    add_column :ptns_mmbs, :newreg, :boolean
  end
end
