class AddAdCodeToBills < ActiveRecord::Migration[5.1]
  def change
    add_column :bills, :ad_code, :text
  end
end
