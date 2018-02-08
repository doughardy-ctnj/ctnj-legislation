class AddSessionNumberToBills < ActiveRecord::Migration[5.1]
  def change
    add_column :bills, :session_number, :string
  end
end
