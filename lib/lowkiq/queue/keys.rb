module Lowkiq
  module Queue
    class Keys
      PREFIX = 'lowkiq:A:v1'.freeze

      def initialize(name)
        @prefix = [PREFIX, name].join(':').freeze
      end

      def processed_key
        [@prefix, :processed].join(':')
      end

      def failed_key
        [@prefix, :failed].join(':')
      end

      def all_ids_lex_zset
        [@prefix, :all_ids_lex].join(':')
      end

      def all_ids_scored_by_perform_in_zset
        [@prefix, :all_ids_scored_by_perfrom_in].join(':')
      end

      def all_ids_scored_by_retry_count_zset
        [@prefix, :all_ids_scored_by_retry_count].join(':')
      end

      def ids_scored_by_perform_in_zset(shard)
        [@prefix, :ids_scored_by_perform_in, shard].join(':')
      end

      def payloads_zset(id)
        [@prefix, :payloads, id].join(':')
      end

      def errors_hash
        [@prefix, :errors].join(':')
      end

      def processing_length_by_shard_hash
        [@prefix, :processing_length_by_shard].join(':')
      end

      def processing_ids_with_perform_in_hash(shard)
        [@prefix, :processing, :ids_with_perform_in, shard].join(':')
      end

      def processing_ids_with_retry_count_hash(shard)
        [@prefix, :processing, :ids_with_retry_count, shard].join(':')
      end

      def processing_payloads_zset(id)
        [@prefix, :processing, :payloads, id].join(':')
      end

      def processing_errors_hash(shard)
        [@prefix, :processing, :errors, shard].join(':')
      end

      def morgue_all_ids_lex_zset
        [@prefix, :morgue, :all_ids_lex].join(':')
      end

      def morgue_all_ids_scored_by_updated_at_zset
        [@prefix, :morgue, :all_ids_scored_by_updated_at].join(':')
      end

      def morgue_payloads_zset(id)
        [@prefix, :morgue, :payloads, id].join(':')
      end

      def morgue_errors_hash
        [@prefix, :morgue, :errors].join(':')
      end
    end
  end
end
