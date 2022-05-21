require 'rails_helper'

RSpec.describe AnswersController, type: :controller do
  let(:question) { create(:question, author: user) }
  let(:answer) {create(:answer, question: question, author: user)}
  let(:user) { create(:user) }

  describe 'POST #create' do
    before { login (user) }
    context 'with valid attributes' do
      it 'saves a new answer for question in the database' do
        expect { post :create, params: { question_id: question, answer: attributes_for(:answer)}}.to change(question.answers, :count).by(1)
      end

      it 'redirects to show view' do
        post :create, params: {question_id: question, answer: attributes_for(:answer)}
        expect(response).to redirect_to assigns(:question)
      end
    end

    context 'with invalid attributes' do
      it 'does not save the answer' do
        expect { post :create, params: { question_id: question, answer: attributes_for(:answer, :invalid)}}.to_not change(question.answers, :count)
      end

      it 're-renders new view' do
        post :create, params: { question_id: question, answer: attributes_for(:answer, :invalid)}
        expect(response).to render_template('questions/show')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:answer) { create(:answer, question: question, author: user) }

    context 'Author' do
      before { login(user) }

      it 'deletes the answer' do
        expect { delete :destroy, params: { id: answer } }.to change(Answer, :count).by(-1)
      end

      it 'redirect to the question' do
        delete :destroy, params: { id: answer }
        expect(response).to redirect_to question_path(question)
      end
    end
  end
end