require 'spec_helper'
require 'rack/test'

describe 'QVoto App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  shared_examples 'valid asset' do
    let(:asset_content) { File.read(File.join(__dir__, '../assets/', asset)) }

    before do
      get "/assets/#{ asset }"
    end

    it 'valid status' do
      expect(last_response).to be_ok
    end

    it 'valid content' do
      expect(last_response.body).to eq asset_content
    end
  end

  describe 'assets' do
    describe 'lib.js' do
      let(:asset) { 'lib.js' }

      it_behaves_like 'valid asset'
    end

    describe 'style.css' do
      let(:asset) { 'style.css' }

      it_behaves_like 'valid asset'
    end
  end

  describe '/server-info' do
    before do
      get '/server-info'
    end

    it 'has a valid status' do
      expect(last_response).to be_ok
    end

    it 'returns ok as the body content' do
      expect(last_response.body).to eq 'ok'
    end
  end

  describe '/graph' do
    let(:quid)        { 'quid' }
    let(:json_answer) { { an: 'answer' } }
    let(:rack_env)    { {} }
    let(:answer) do
      instance_double(QVoto::Answer, error: error, to_json: json_answer)
    end

    before do
      allow(QVoto::Answer)
        .to receive(:find_by_quid).with(quid).and_return(answer)
      get '/graph', { quid: quid }, rack_env
    end

    context 'when qvoto answer generates an error' do
      let(:error) { true }

      it 'renders the error template' do
        expect(last_response.body)
          .to include 'Error accediendo a los datos de la respuesta'
      end
    end

    context 'when qvoto answer returns a valid answer' do
      let(:error) { false }

      context 'when the client accepts application/json' do
        let(:rack_env) { { 'HTTP_ACCEPT' => 'application/json' } }

        it 'renders the answer in JSON format' do
          expect(last_response.body).to eq json_answer.to_json
        end
      end

      context 'when the client does not accept application/json' do
        it 'renders the graph template with the answer' do
          expect(last_response.body)
            .to include '<div id="chart"></div>'
        end
      end
    end
  end
end
