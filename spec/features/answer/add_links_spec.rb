require 'rails_helper'

feature 'User can add links to answer', "
  In order to provide additional info to an answer
  As an answer's author
  I'd like to be able to add links
" do
  given(:user) { create(:user) }
  given(:question) { create(:question, author: user) }
  given(:gist_url) { 'https://gist.github.com/leri-berry/b7147f15b7e6f4301f7b3c08e9678dc2' }

  scenario 'User adds link when give an answer', js: true do
    sign_in(user)
    visit question_path(question)

    fill_in 'Body', with: 'My answer'
    fill_in 'Link name', with: 'My gist'
    fill_in 'Url', with: gist_url
    click_on 'Leave an answer'

    within '.answers' do
      expect(page).to have_link 'My gist', href: gist_url
    end
  end
end
