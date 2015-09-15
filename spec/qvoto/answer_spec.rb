require 'spec_helper'

describe QVoto::Answer do
  let(:form_uids)   { { 'xyz' => 'private_uid' } }
  let(:quid)        { '123xyz456' }
  let(:since)       { 66 }

  before do
    allow(subject).to receive(:since_time).and_return(since)
    stub_const('QVoto::Answer::SINCE_TIME', since)
    stub_const('QVoto::Answer::FORM_UIDS',  form_uids)
  end

  subject { described_class.new(quid) }

  describe '.find_by_quid' do
    it 'creates an instance with the quid, fetchs the form and returns itself' do
      expect(described_class).to receive(:new).with(quid).and_return(subject)
      expect(subject).to receive(:fetch!).with(no_args)
      expect(described_class.find_by_quid(quid)).to eq subject
    end
  end

  describe 'initializing' do
    let(:quid) { '12334xyz.32' }

    it 'sets the quid' do
      expect(subject.quid).to eq quid
    end

    it 'sets error to nil' do
      expect(subject.error).to be_nil
    end
  end

  describe 'with testing response' do
    let(:typeform_response) do
      JSON.parse(File.read(File.join(__dir__, '../test_response.json')))
    end
    let(:typeform_stub) do
      allow(QVoto::Typeform).to receive(:find_by_form_uid)
        .with('private_uid', filters)
    end
    let(:filters) { { completed: true, since: since, :'order[]' => order } }
    let(:order)   { 'date_land,desc' }
    let(:quid)    { '143997356437xyz0.74341626638602465'}

    describe 'to_json' do
      let(:aggregator) { instance_double(QVoto::Aggregator) }
      let(:answers)    { { "textfield_9959575" => "aa" } }
      let(:questions) do
        [ { "id" => "textfield_9959575", "question" => "Fill the thing" } ]
      end

      before do
        typeform_stub.and_return(typeform_response)
        allow(QVoto::Aggregator).to receive(:new).and_return(aggregator)
      end

      after do
        subject.to_json
      end

      it 'calls fetch when the typeform has not been fetched yet' do
        expect(subject).to receive(:fetch!).and_call_original
      end

      context 'when the form data has been already loaded' do
        before do
          subject.fetch!
        end

        it 'does not call fetch!' do
          expect(subject).not_to receive(:fetch!)
        end
      end

      it 'calls the aggreation with the right parameters' do
        expect(QVoto::Aggregator).to receive(:new)
          .with('private_uid', answers, questions)
      end

      it 'calls to_json in the aggregator' do
        expect(aggregator).to receive(:to_json)
      end
    end

    describe 'fetch!' do
      let(:response)   { typeform_response }

      context 'when the quid has an invalid form key' do
        let(:quid) { '12334no_public_uid.32' }
        before     { subject.fetch! }

        it 'sets the error' do
          expect(subject.error).to eq('Invalid Form')
        end
      end

      context 'when typeform raises an error' do
        before do
          typeform_stub.and_raise(QVoto::Exceptions::RequestWithErrors)
          subject.fetch!
        end

        it 'sets the error' do
          expect(subject.error).to eq('Request with errors')
        end
      end

      context 'when typeform does not raise an error' do
        before do
          typeform_stub.and_return(response)
          subject.fetch!
        end

        context 'when not a valid quid' do
          let(:quid) { '143997356437xyz99' }

          it 'sets the error' do
            expect(subject.error).to eq('Not valid form Found')
          end
        end

        context 'when multiple guids are found' do
          let(:quid)     { '143997356437xyz0.74341626638602465'}
          let(:response) do
            typeform_response.tap do |hash|
              hash["responses"][1]["hidden"]["quid"] = quid
            end
          end

          it 'sets the error' do
            expect(subject.error).to eq('Not valid form Found')
          end
        end

        context 'when is a valid quid' do
          let(:quid) { '143997356437xyz0.74341626638602465'}

          it 'does not have an error' do
            expect(subject.error).to be_nil
          end

          it 'has the form data in the form_data accessor' do
            expect(subject.form_data).to eql(response)
          end
        end
      end
    end
  end
end
