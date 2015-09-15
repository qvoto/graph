require 'spec_helper'

describe QVoto::Typeform do
  describe '.connection' do
    it 'returns a valid instance of faraday' do
      expect(described_class.connection).to be_a Faraday::Connection
    end

    it 'has the right url' do
      expect(described_class.connection.url_prefix.to_s)
        .to eq 'https://api.typeform.com/'
    end
  end

  context 'stubing connection' do
    let(:test_response)  { File.read(File.join(__dir__, '../test_response.json')) }
    let(:params)         { { } }
    let(:default_params) { { key: 'TEST_KEY' } }
    let(:query_params) do
      default_params.merge(params).map do |(k,v)|
        "#{ k }=#{ v }"
      end.join("&")
    end
    let(:connection) do
      Faraday.new do |builder|
        builder.adapter :test, Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/v0/form/#{ form_uid }?#{ query_params }") do |env|
            [ status_code, {}, test_response ]
          end
        end
      end
    end

    before do
      stub_const('QVoto::Typeform::API_KEY',  'TEST_KEY')
      allow(described_class).to receive(:connection).and_return(connection)
    end

    describe '.find_by_form_uid' do
      let(:form_uid) { 'TEST_UID' }
      let(:result)   { described_class.find_by_form_uid(form_uid, params) }
      let(:params) { { since: Time.now.to_i } }

      context 'whith a valid status' do
        let(:status_code) { 200 }

        it 'returns the whole response' do
          expect(result).to eq(JSON.parse(test_response))
        end
      end

      context 'with an invalid status' do
        let(:status_code) { 500 }

        it 'raises an exception' do
          expect { result }.to raise_error QVoto::Exceptions::RequestWithErrors
        end
      end
    end
  end
end
