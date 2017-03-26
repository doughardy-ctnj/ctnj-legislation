class CreateBills < ActiveRecord::Migration[5.0]
  def change
    create_table :bills do |t|
      t.string :bill_id
      t.string :openstate_id
      t.string :title
      t.jsonb :data

      t.timestamps
    end
  end
end
