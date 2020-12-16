module Lowkiq
  module Queue
    class ShardMetrics
      def initialize(redis_pool)
        @redis_pool = redis_pool
        @timestamp = Utils::Timestamp.method(:now)
      end

      def call(queues)
        result = @redis_pool.with do |redis|
          redis.pipelined do
            queues.each { |queue| pipeline redis, queue }
          end
        end

        result.each_slice(pipeline_count).map do |res|
          coerce(res)
        end
      end

      private

      def pipeline(redis, id)
        name = id[:queue_name]
        shard = id[:shard]

        keys = Keys.new name

        # lag [id, score]
        redis.zrange keys.ids_scored_by_perform_in_zset(shard),
                     0, 0, with_scores: true
      end

      def pipeline_count
        1
      end

      def coerce(result)
        OpenStruct.new lag: coerce_lag(result[0])
      end

      def coerce_lag(res)
        _id, score = res.first

        return 0 if score.nil?
        lag = @timestamp.call - score.to_f
        return 0 if lag < 0
        lag
      end
    end
  end
end
