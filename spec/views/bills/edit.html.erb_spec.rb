require 'rails_helper'

RSpec.describe "bills/edit", type: :view do
  before(:each) do
    @bill = assign(:bill, Bill.create!(
      :bill_id => "MyString",
      :openstate_id => "MyString",
      :title => "MyString",
      :data => ""
    ))
  end

  it "renders the edit bill form" do
    render

    assert_select "form[action=?][method=?]", bill_path(@bill), "post" do

      assert_select "input#bill_bill_id[name=?]", "bill[bill_id]"

      assert_select "input#bill_openstate_id[name=?]", "bill[openstate_id]"

      assert_select "input#bill_title[name=?]", "bill[title]"

      assert_select "input#bill_data[name=?]", "bill[data]"
    end
  end
end
