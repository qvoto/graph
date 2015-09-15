module QVoto
  module Exceptions
    class InvalidForm       < StandardError; end
    class NotFound          < StandardError; end
    class MultipleFound     < StandardError; end
    class RequestWithErrors < StandardError
      attr_accessor :response
    end
  end
end
