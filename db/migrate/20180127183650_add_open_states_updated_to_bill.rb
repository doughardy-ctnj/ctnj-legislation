class AddOpenStatesUpdatedToBill < ActiveRecord::Migration[5.1]
  def change
    add_column :bills, :open_states_updated_at, :date
  end
end
