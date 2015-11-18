module QVoto
  class Answer

    # Relate public uids in the quid with internal typeforms uids
    #             'xyz' => testform, 'wqd' => qvoto
    FORM_UIDS = { 'xyz' => 'ISbyVw', 'wqd' => 'SZur3p', 
                  'oht' => 'Dpj44O' }

    # Number of seconds ago within the response should have been
    # created. It will be passed to the Typeform API. 5 minutes now.
    SINCE_TIME = 300

    class << self
      def find_by_quid(quid)
        new(quid).tap do |instance|
          instance.fetch!
        end
      end
    end

    attr_reader :quid, :result, :error, :form_data, :quid_result

    def initialize(quid)
      @quid     = quid
      @error    = nil
    end

    def fetch!
      validate_and_find_typeform
    rescue QVoto::Exceptions::NotFound,
           QVoto::Exceptions::MultipleFound,
           QVoto::Exceptions::InvalidForm,
           QVoto::Exceptions::RequestWithErrors => exception
      handle_exception(exception)
    end

    def to_json
      fetch! unless @form_data
      aggreated_results.to_json
    end

    private

    def validate_and_find_typeform
      validate_form_uid
      fetch_typeform
      validate_form_data
    end

    def fetch_typeform
      @form_data = QVoto::Typeform.find_by_form_uid(form_uid, filters)
    end

    def filters
      { completed: true, :'order[]' => 'date_land,desc' }.tap do |hash|
        hash.merge!(since: since_time) unless ENV['QVOTO_DEBUG']
      end
    end

    def since_time
      Time.now.utc.to_i - SINCE_TIME
    end

    def validate_form_uid
      raise QVoto::Exceptions::InvalidForm unless valid_form_uid?
    end

    def validate_form_data
      result = extract_result_by_hidden_fields

      case result.count
      when 0 then raise QVoto::Exceptions::NotFound
      when 1 then @quid_result = result.first
      else
        raise QVoto::Exceptions::MultipleFound
      end
    end

    def questions
      form_data['questions'] || []
    end

    def hidden_fields
      { quid: quid }
    end

    def answers
      quid_result['answers']
    end

    def extract_result_by_hidden_fields
      return form_data['responses'] unless hidden_fields.any?

      form_data['responses'].select do |response|
        response_match_hiddens(response['hidden'])
      end
    end

    # TODO
    def response_match_hiddens(hiddens)
      return false if hiddens.empty? # does not have a hidden value

      hidden_fields.each do |key, value|
        return false unless hiddens[key.to_s] == value
      end
      true
    end

    def public_form_uid
      quid.split('.').first.gsub(/[\d]/, '')
    end

    def form_uid
      @form_uid ||= FORM_UIDS.fetch(public_form_uid)
    end

    def valid_form_uid?
      FORM_UIDS.key?(public_form_uid)
    end

    def aggreated_results
      @aggreated_results ||= QVoto::Aggregator.new(form_uid, answers, questions)
    end

    # TODO
    # handle exception somehow
    def handle_exception(exception)
      case exception
      when QVoto::Exceptions::NotFound, QVoto::Exceptions::MultipleFound
        @error = 'Not valid form Found'
      when QVoto::Exceptions::InvalidForm
        @error = 'Invalid Form'
      when QVoto::Exceptions::RequestWithErrors
        @error = 'Request with errors'
      end
    end
  end
end
