class AddStatdlToPtnsMmbs < ActiveRecord::Migration[5.2]
  def change
    add_column :ptns_mmbs, :statdl, :string
  end
end
