require 'rails_helper'

RSpec.describe "bills/index", type: :view do
  before(:each) do
    assign(:bills, [
      Bill.create!(
        :bill_id => "Bill",
        :openstate_id => "Openstate",
        :title => "Title",
        :data => ""
      ),
      Bill.create!(
        :bill_id => "Bill",
        :openstate_id => "Openstate",
        :title => "Title",
        :data => ""
      )
    ])
  end

  it "renders a list of bills" do
    render
    assert_select "tr>td", :text => "Bill".to_s, :count => 2
    assert_select "tr>td", :text => "Openstate".to_s, :count => 2
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
