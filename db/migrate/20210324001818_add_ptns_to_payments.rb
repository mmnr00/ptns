class AddPtnsToPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :payments, :ptns_mmb_id, :integer
  end
end
