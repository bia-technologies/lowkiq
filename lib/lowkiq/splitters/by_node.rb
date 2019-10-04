module Lowkiq
  module Splitters
    class ByNode
      def initialize(number_of_nodes, node_number, threads_per_node)
        @number_of_nodes = number_of_nodes
        @node_number = node_number
        @threads_per_node = threads_per_node
      end

      def call(shard_handlers)
        groups_for_nodes = Utils::Array.new(shard_handlers).in_transposed_groups(@number_of_nodes)
        groups_for_node = groups_for_nodes[@node_number]
        Utils::Array.new(groups_for_node)
          .in_transposed_groups(@threads_per_node)
          .reject(&:empty?)
      end
    end
  end
end
