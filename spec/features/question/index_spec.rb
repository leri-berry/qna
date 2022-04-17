require 'rails_helper'

feature 'User can view a list of questions', %q{
  In order to find a question
  As an user
  I'd like to be able to view a list of questions
} do

  given!(:questions) { create_list(:question, 3) }

  scenario 'view a list of questions' do
    visit questions_path
    questions.each { |question| expect(page).to have_content(question.title) }

   end
 end