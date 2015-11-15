module QVoto
  class Aggregator
    class << self
      def settings
        @settings ||= setting_files.each_with_object({}) do |file, hash|
          form_id = File.basename(file, '.json')
          hash.merge!(form_id => JSON.parse(File.read(file)))
        end.freeze
      end

      def setting_files
        Dir[File.join(__dir__, '..', 'settings', '*.json')]
      end
    end

    def initialize(form_uid, answers, questions)
      @form_uid  = form_uid
      @answers   = answers
      @questions = questions
    end

    def to_json
      @results ||= generate_result
    end

    private

    attr_accessor :answers, :form_uid

    def generate_result
      parties.each_with_object({}) do |(key, data), result|
        value = {
          "affinity" => percent_of(affinity(key, data['preset'])),
          "name"     => data['name'],
          "colour"   => data['colour'],
        }
        result.merge!(key => value)
      end
    end

    def parties
      settings['parties']
    end

    def settings
      self.class.settings[form_uid]
    end

    def percent_of(number)
      (number.to_f / ordered_questions.count.to_f * 100.0).to_i
    end

    def affinity(key, preset)
      total = 0
      ordered_questions.each_with_index do |question, index|
        answer = answers[question["id"]]
        total += 1 if answer == preset.at(index)
      end
      total
    end

    def ordered_questions
      @questions.select do |question|
        question['id'].match(/list_\d+_choice/)
      end
    end
  end
end
