class AddTextToBills < ActiveRecord::Migration[5.0]
  def change
    add_column :bills, :text, :jsonb
  end
end
