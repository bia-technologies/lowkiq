module Lowkiq
  module Queue
    class QueueMetrics
      def initialize(redis_pool)
        @redis_pool = redis_pool
        @timestamp = Utils::Timestamp.method(:now)
      end

      def call(queues)
        result = @redis_pool.with do |redis|
          #redis.pipelined do
          redis.multi do |rs|
            queues.each { |queue| pipeline rs, queue }
          end
        end

        result.each_slice(pipeline_count).map do |res|
          coerce(res)
        end
      end

      private

      def pipeline(redis, name)
        keys = Keys.new name

        # fresh
        redis.zcount keys.all_ids_scored_by_retry_count_zset, -1, -1

        # retries
        redis.zcount keys.all_ids_scored_by_retry_count_zset, 0, '+inf'

        # morgue_length
        redis.zcard keys.morgue_all_ids_scored_by_updated_at_zset

        # lag [id, score]
        redis.zrange keys.all_ids_scored_by_perform_in_zset,
                     0, 0, with_scores: true
        # processed
        redis.get keys.processed_key

        # failed
        redis.get keys.failed_key

        # busy []
        redis.hvals keys.processing_length_by_shard_hash
      end

      def pipeline_count
        7
      end

      def coerce(result)
        length = result[0] + result[1]
        OpenStruct.new length:        length,
                       fresh:         result[0],
                       retries:       result[1],
                       morgue_length: result[2],
                       lag:           coerce_lag(result[3]),
                       processed:     result[4].to_i,
                       failed:        result[5].to_i,
                       busy:          coerce_busy(result[6])
      end

      def coerce_lag(res)
        _id, score = res.first
        return 0.0 if score.nil?
        lag = @timestamp.call - score
        return 0.0 if lag < 0.0
        lag
      end

      def coerce_busy(res)
        res.map(&:to_i).reduce(0, &:+)
      end
    end
  end
end
