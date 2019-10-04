module Lowkiq
  module Splitters
    class Default
      def initialize(threads_per_node)
        @threads_per_node = threads_per_node
      end

      def call(shard_handlers)
        Utils::Array.new(shard_handlers)
          .in_transposed_groups(@threads_per_node)
          .reject(&:empty?)
      end
    end
  end
end
