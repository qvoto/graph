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
end
