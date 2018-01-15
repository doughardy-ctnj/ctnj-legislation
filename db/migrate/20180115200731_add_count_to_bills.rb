class AddCountToBills < ActiveRecord::Migration[5.1]
  def change
    add_column :bills, :votes_count, :integer
    # Bill.find_each { |bill| Bill.reset_counters(bill.id, :votes) }
  end
end
