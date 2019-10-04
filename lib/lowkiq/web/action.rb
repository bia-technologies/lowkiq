module Lowkiq
  module Web
    class Action
      def self.segments_to_regex(segments)
        prepared = segments.map do |segment|
          case segment
          when Symbol
            "(?<#{segment}>[^\/]+)"
          else
            segment
          end
        end.join( '/' )
        Regexp.new '\A' + '/' + prepared + '\z'
      end

      def initialize(request_method, segments, &body)
        @request_method = request_method
        @url_pattern = self.class.segments_to_regex(segments)
        @body = body
      end

      def call(req)
        return if @request_method != req.request_method
        match = @url_pattern.match req.path_info
        return unless match
        data = @body.call req, match
        [200, {}, [JSON.generate(data)]]
      end
    end
  end
end
