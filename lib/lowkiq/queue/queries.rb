module Lowkiq
  module Queue
    class Queries
      def initialize(redis_pool, name)
        @pool = redis_pool
        @keys = Keys.new name
        @fetch = Fetch.new name
      end

      def range_by_id(min, max, limit: 10)
        @pool.with do |redis|
          ids = redis.zrangebylex(
            @keys.all_ids_lex_zset,
            min, max,
            limit: [0, limit]
          )
          _fetch redis, ids
        end
      end

      def rev_range_by_id(max, min, limit: 10)
        @pool.with do |redis|
          ids = redis.zrevrangebylex(
            @keys.all_ids_lex_zset,
            max, min,
            limit: [0, limit]
          )
          _fetch redis, ids
        end
      end

      def range_by_perform_in(min, max, limit: 10)
        @pool.with do |redis|
          ids = redis.zrangebyscore(
            @keys.all_ids_scored_by_perform_in_zset,
            min, max,
            limit: [0, limit]
          )
          _fetch redis, ids
        end
      end

      def rev_range_by_perform_in(max, min, limit: 10)
        @pool.with do |redis|
          ids = redis.zrevrangebyscore(
            @keys.all_ids_scored_by_perform_in_zset,
            max, min,
            limit: [0, limit]
          )
          _fetch redis, ids
        end
      end

      def range_by_retry_count(min, max, limit: 10)
        @pool.with do |redis|
          ids = redis.zrangebyscore(
            @keys.all_ids_scored_by_retry_count_zset,
            min, max,
            limit: [0, limit]
          )
          _fetch redis, ids
        end
      end

      def rev_range_by_retry_count(max, min, limit: 10)
        @pool.with do |redis|
          ids = redis.zrevrangebyscore(
            @keys.all_ids_scored_by_retry_count_zset,
            max, min,
            limit: [0, limit]
          )
          _fetch redis, ids
        end
      end

      def morgue_range_by_id(min, max, limit: 10)
        @pool.with do |redis|
          ids = redis.zrangebylex(
            @keys.morgue_all_ids_lex_zset,
            min, max,
            limit: [0, limit]
          )
          _morgue_fetch redis, ids
        end
      end

      def morgue_rev_range_by_id(max, min, limit: 10)
        @pool.with do |redis|
          ids = redis.zrevrangebylex(
            @keys.morgue_all_ids_lex_zset,
            max, min,
            limit: [0, limit]
          )
          _morgue_fetch redis, ids
        end
      end

      def morgue_range_by_updated_at(min, max, limit: 10)
        @pool.with do |redis|
          ids = redis.zrangebyscore(
            @keys.morgue_all_ids_scored_by_updated_at_zset,
            min, max,
            limit: [0, limit]
          )
          _morgue_fetch redis, ids
        end
      end

      def morgue_rev_range_by_updated_at(max, min, limit: 10)
        @pool.with do |redis|
          ids = redis.zrevrangebyscore(
            @keys.morgue_all_ids_scored_by_updated_at_zset,
            max, min,
            limit: [0, limit]
          )
          _morgue_fetch redis, ids
        end
      end

      def fetch(ids)
        @pool.with do |redis|
          _fetch redis, ids
        end
      end

      def morgue_fetch(ids)
        @pool.with do |redis|
          _morgue_fetch redis, ids
        end
      end

      private

      def _fetch(redis, ids)
        @fetch.fetch(redis, :multi, ids)
      end

      def _morgue_fetch(redis, ids)
        @fetch.morgue_fetch(redis, :multi, ids)
      end
    end
  end
end
