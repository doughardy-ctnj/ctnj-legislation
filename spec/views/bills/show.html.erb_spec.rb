require 'rails_helper'

RSpec.describe "bills/show", type: :view do
  before(:each) do
    @bill = assign(:bill, Bill.create!(
      :bill_id => "Bill",
      :openstate_id => "Openstate",
      :title => "Title",
      :data => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Bill/)
    expect(rendered).to match(/Openstate/)
    expect(rendered).to match(/Title/)
    expect(rendered).to match(//)
  end
end
