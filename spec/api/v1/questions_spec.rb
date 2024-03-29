require 'rails_helper'

describe 'Questions API', type: :request do
  let(:headers) { { 'ACCEPT' => 'application/json' } }
  describe 'GET /api/v1/questions' do
    let(:api_path) { '/api/v1/questions' }
    let(:method) { :get }

    it_behaves_like 'API Authorizable'

    context 'authorized' do
      let(:access_token) { create(:access_token) }
      let!(:questions) { create_list(:question, 2) }
      let(:question) { questions.first }
      let(:question_response) { json['questions'].first }
      let!(:answers) { create_list(:answer, 3, question: question) }

      before do
        do_request(method, api_path,
                   params: { access_token: access_token.token },
                   headers: headers)
      end

      it_behaves_like 'Response successful'

      it_behaves_like 'List of items returnable' do
        let(:responce_resource) { json['questions'] }
        let(:resource) { questions.size }
      end

      it_behaves_like 'Public fields' do
        let(:attributes) { %w[id title body created_at updated_at] }
        let(:response_resource) { question_response }
        let(:resource) { question }
      end

      it 'contains user object' do
        expect(question_response['user_id']).to eq question.user_id
      end

      it 'contains short title' do
        expect(question_response['short_title']).to eq question.title.truncate(7)
      end

      describe 'answers' do
        let(:answer) { answers.first }
        let(:answer_response) { question_response['answers'].first }

        it 'returns list of answers' do
          expect(question_response['answers'].size).to eq 3
        end

        it 'returns all public fields' do
          %w[id body user_id created_at updated_at].each do |attr|
            expect(answer_response[attr]).to eq answer.send(attr).as_json
          end
        end
      end
    end
  end

  describe 'GET /api/v1/questions/:id' do
    let(:user) { create(:user) }
    let(:question) { create(:question, :with_attachment, author: user) }
    let!(:answers) { create_list(:answer, 3, question: question) }
    let!(:links) { create_list(:link, 3, linkable: question) }
    let!(:comments) { create_list(:comment, 3, commentable: question, user: user) }
    let(:question_response) { json['question'] }
    let(:api_path) { "/api/v1/questions/#{question.id}" }
    let(:method) { :get }
    let(:access_token) { create(:access_token) }

    it_behaves_like 'API Authorizable'

    before do
      do_request(method, api_path,
                 params: { access_token: access_token.token },
                 headers: headers)
    end

    it_behaves_like 'Response successful'

    it_behaves_like 'Public fields' do
      let(:attributes) { %w[id title body created_at updated_at] }
      let(:response_resource) { question_response }
      let(:resource) { question }
    end

    context 'Answers' do
      it_behaves_like 'List of items returnable' do
        let(:responce_resource) { question_response['answers'] }
        let(:resource) { question.answers.size }
      end
    end

    context 'Files' do
      it_behaves_like 'List of items returnable' do
        let(:responce_resource) { question_response['files'] }
        let(:resource) { question.files.size }
      end
    end

    context 'Links' do
      it_behaves_like 'List of items returnable' do
        let(:responce_resource) { question_response['links'] }
        let(:resource) { question.links.size }
      end
    end

    context 'Comments' do
      it_behaves_like 'List of items returnable' do
        let(:responce_resource) { question_response['comments'] }
        let(:resource) { question.comments.size }
      end
    end
  end

  describe 'POST /api/v1/questions' do
    let(:api_path) { '/api/v1/questions' }
    let(:method) { :post }
    let(:access_token) { create(:access_token) }

    it_behaves_like 'API Authorizable'

    context 'authorized' do
      context 'with valid attributes' do
        let(:params) do
          { question: attributes_for(:question),
            access_token: access_token.token }
        end

        it 'saves a new question in database' do
          expect { post api_path, params: params }.to change(Question, :count).by(1)
        end

        it 'returns successful status' do
          post api_path, params: params
          expect(response).to be_successful
        end
      end

      context 'with invalid attributes' do
        let(:params) do
          { question: attributes_for(:question, :invalid),
            access_token: access_token.token }
        end
        it 'does not saves question' do
          expect { post api_path, params: params }.to_not change(Question, :count)
        end

        before { post api_path, params: params }

        it 'returns unprocessable_entity status' do
          expect(response.status).to eq 422
        end

        it 'contains list of errors' do
          expect(response.body).to match(/errors/)
        end
      end
    end
  end

  describe 'DELETE /api/v1/questions' do
    let(:author) { create(:user) }
    let!(:question) { create(:question, author: author) }
    let(:api_path) { "/api/v1/questions/#{question.id}" }
    let(:method) { :delete }

    it_behaves_like 'API Authorizable'

    context 'authorized' do
      let(:access_token) { create(:access_token, resource_owner_id: author.id) }

      before { delete api_path, params: { id: question, access_token: access_token.token } }

      it_behaves_like 'Response successful'

      it 'deletes the question' do
        expect(Question.count).to eq 0
      end

      it 'returns successful message' do
        expect(json['messages']).to include('Your question deleted')
      end
    end

    context 'not authorized' do
      let(:user) { create(:user) }
      let(:other_access_token) { create(:access_token, resource_owner_id: user.id) }
      let(:params) { { id: question, access_token: other_access_token.token } }

      before { delete api_path, params: params, headers: headers }

      it 'tries to delete question' do
        expect(Question.count).to eq 1
      end
    end
  end

  describe 'PATCH /api/v1/questions' do
    let(:author) { create(:user) }
    let!(:question) { create(:question, author: author) }
    let(:api_path) { "/api/v1/questions/#{question.id}" }
    let(:method) { :patch }

    it_behaves_like 'API Authorizable'

    context 'authorized' do
      let(:access_token) { create(:access_token, resource_owner_id: author.id) }

      context 'with valid attributes' do
        before do
          patch api_path,
                params: { id: question, question: { title: 'new title', body: 'new body' },
                          access_token: access_token.token }
        end

        it_behaves_like 'Response successful'

        it 'assigns the requested question to @question' do
          expect(assigns(:question)).to eq question
        end

        it 'changes question attributes' do
          question.reload

          expect(question.title).to eq 'new title'
          expect(question.body).to eq 'new body'
        end
      end

      context 'with invalid attributes' do
        before do
          patch api_path,
                params: { id: question, question: attributes_for(:question, :invalid),
                          access_token: access_token.token }
        end

        it 'not changes question attirbutes' do
          question.reload

          expect(question.title).to eq 'MyString'
          expect(question.body).to eq 'MyText'
        end

        it 'returns unprocessable_entity status' do
          expect(response.status).to eq 422
        end

        it 'contains list of errors' do
          expect(response.body).to match(/errors/)
        end
      end

      context 'not author tries to update question' do
        let(:user) { create(:user) }
        let(:other_access_token) { create(:access_token, resource_owner_id: user.id) }

        before do
          patch api_path,
                params: { id: question, question: attributes_for(:question), access_token: other_access_token.token }
        end

        it 'not changes question attirbutes' do
          question.reload

          expect(question.title).to eq 'MyString'
          expect(question.body).to eq 'MyText'
        end
      end
    end
  end
end
