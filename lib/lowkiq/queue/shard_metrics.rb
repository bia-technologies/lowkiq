module Lowkiq
  module Queue
    class ShardMetrics
      def initialize(redis_pool)
        @redis_pool = redis_pool
        @timestamp = Utils::Timestamp.method(:now)
      end

      def call(queues)
        result = @redis_pool.with do |redis|
          redis.pipelined do |pipe|
            queues.each { |queue| pipeline pipe, queue }
          end
        end

        result.each_slice(pipeline_count).map do |res|
          coerce(res)
        end
      end

      private

      def pipeline(pipe, id)
        name = id[:queue_name]
        shard = id[:shard]

        keys = Keys.new name

        # lag [id, score]
        pipe.zrange keys.ids_scored_by_perform_in_zset(shard),
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
        return 0.0 if score.nil?
        lag = @timestamp.call - score
        return 0.0 if lag < 0.0
        lag
      end
    end
  end
end
