require "rails_helper"

RSpec.feature "Vote for a bill", :type => :feature do
  scenario "User votes up a bill" do
    bill = FactoryBot.create(:bill)
    sign_in FactoryBot.create(:user)
    visit "/bills/#{bill.id}"
    click_button "Vote for bill" # Vote up

    expect(page).to have_text("Thank you for your vote.")
    # expect votes for bill to increase by 1
  end
end
