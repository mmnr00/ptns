class AddStatToPtnsMmbs < ActiveRecord::Migration[5.2]
  def change
    add_column :ptns_mmbs, :stat, :string
  end
end
