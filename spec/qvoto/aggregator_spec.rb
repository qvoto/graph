require 'spec_helper'

describe QVoto::Aggregator do
  let(:questions) do
    [
      {
        "id"       => "list_1_choice",
        "question" => "Tortilla con cebolla"
      },
      {
        "id"       => "list_2_choice",
        "question" => "Private Source Everywhere"
      },
      {
        "id"       => "list_3_choice",
        "question" => "Frio o caliente"
      }
    ]
  end
  let(:answers) do
    {
      "list_1_choice" => "a favor",
      "list_2_choice" => "en contra",
      "list_3_choice" => "neutral"
    }
  end
  let(:form_uid) { 'XXX' }

  subject { described_class.new(form_uid, answers, questions) }

  describe '#to_json' do
    let(:settings) do
      {
        "XXX" => {
          "parties" => {
            "PPP" => {
              "name"   => "Partido Particulado Particular",
              "colour" => "pink",
              "preset" => [
                "a favor",
                "neutral",
                "en contra"
              ]
            },
            "EOSP" => {
              "name"   => "Eolos Oh Si Plis",
              "colour" => "blue",
              "preset" => [
                "en contra",
                "a favor",
                "neutral"
              ]
            },
            "Fofemos" => {
               "name"   => "Fi fe fuede",
               "colour" => "orange",
               "preset" => [
                 "a favor",
                 "en contra",
                 "neutral"
               ]
            }
          }
        }
      }
    end

    before do
      allow(described_class).to receive(:settings).and_return(settings)
    end

    it 'exports the answers correctly' do
      expect(subject.to_json).to eql({
        'PPP'     => { 'affinity' => 33,  'colour' => 'pink',   'name' => 'Partido Particulado Particular' },
        'EOSP'    => { 'affinity' => 33,  'colour' => 'blue',   'name' => 'Eolos Oh Si Plis' },
        'Fofemos' => { 'affinity' => 100, 'colour' => 'orange', 'name' => 'Fi fe fuede' }
      })
    end
  end

  describe '.settings' do
    let(:settings_path) { Pathname.new(__dir__).join('..', '..', 'settings') }

    it 'has a namespace for each setting files' do
      expect(described_class.settings.keys.count)
        .to eq Dir["#{ settings_path.join('*.json') }"].count
    end

    it 'parses and return the content of each of the the settings file' do
      described_class.settings.each do |form_id, form_settings|
        expect(form_settings)
          .to eq JSON.parse(File.read(settings_path.join("#{ form_id }.json")))
      end
    end
  end
end
