module QVoto
  class Typeform

    API_URL   = 'https://api.typeform.com'
    API_KEY   = ENV['TYPEFORM_KEY']

    class << self
      def find_by_form_uid(uid, options = {})
        new(connection, uid).find(options)
      end

      def connection
        @connection ||= Faraday.new(url: API_URL) do |faraday|
          faraday.request  :url_encoded
          faraday.adapter  Faraday.default_adapter
        end
      end
    end

    attr_reader   :connection, :form_uid

    def initialize(connection, form_uid)
      @connection = connection
      @form_uid   = form_uid
    end

    def find(query)
      params   = build_params(query)
      response = connection.get(form_path, params)

      validate_response(response)
    end

    private

    def validate_response(response)
      return extract_error(response) unless response.status == 200

      JSON.parse(response.body)
    end

    def extract_error(response)
      exception = QVoto::Exceptions::RequestWithErrors.new.tap do |error|
        error.response = response
      end
      raise exception
    end

    def form_path
      "/v0/form/#{ form_uid }"
    end

    def build_params(params)
      params.merge(key: API_KEY)
    end
  end
end
