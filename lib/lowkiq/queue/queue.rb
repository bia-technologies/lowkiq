module Lowkiq
  module Queue
    class Queue
      attr_reader :name, :pool

      def initialize(redis_pool, name, shards_count)
        @pool = redis_pool
        @name = name
        @shards_count = shards_count
        @timestamp = Utils::Timestamp.method(:now)
        @keys = Keys.new name
        @fetch = Fetch.new name
      end

      def push(batch)
        @pool.with do |redis|
          redis.multi do
            batch.each do |job|
              id          = job.fetch(:id)
              perform_in  = job.fetch(:perform_in, @timestamp.call)
              retry_count = job.fetch(:retry_count, -1) # for testing
              payload     = job.fetch(:payload, "")
              score       = job.fetch(:score, @timestamp.call)

              shard = id_to_shard id

              redis.zadd @keys.all_ids_lex_zset, 0, id
              redis.zadd @keys.all_ids_scored_by_perform_in_zset, perform_in, id, nx: true
              redis.zadd @keys.all_ids_scored_by_retry_count_zset, retry_count, id, nx: true

              redis.zadd @keys.ids_scored_by_perform_in_zset(shard), perform_in, id, nx: true
              redis.zadd @keys.payloads_zset(id), score, Lowkiq.dump_payload.call(payload), nx: true
            end
          end
        end
      end

      def pop(shard, limit:)
        @pool.with do |redis|
          ids = redis.zrangebyscore @keys.ids_scored_by_perform_in_zset(shard),
                                    0, @timestamp.call,
                                    limit: [0, limit]
          return [] if ids.empty?

          res = redis.multi do |redis|
            redis.hset @keys.processing_length_by_shard_hash, shard, ids.length

            ids.each do |id|
              redis.zrem @keys.all_ids_lex_zset, id
              redis.zrem @keys.ids_scored_by_perform_in_zset(shard), id

              Script.zremhset redis,
                              @keys.all_ids_scored_by_perform_in_zset,
                              @keys.processing_ids_with_perform_in_hash(shard),
                              id
              Script.zremhset redis,
                              @keys.all_ids_scored_by_retry_count_zset,
                              @keys.processing_ids_with_retry_count_hash(shard),
                              id
              redis.rename @keys.payloads_zset(id),
                           @keys.processing_payloads_zset(id)
              Script.hmove redis,
                           @keys.errors_hash,
                           @keys.processing_errors_hash(shard),
                           id
            end
            processing_data_pipeline(redis, shard, ids)
          end

          res.shift 1 + ids.length * 6
          processing_data_build res, ids
        end
      end

      def push_back(batch)
        @pool.with do |redis|
          timestamp = @timestamp.call
          redis.multi do |redis|
            batch.each do |job|
              id          = job.fetch(:id)
              perform_in  = job.fetch(:perform_in, timestamp)
              retry_count = job.fetch(:retry_count, -1)
              payloads    = job.fetch(:payloads).map do |(payload, score)|
                [score, Lowkiq.dump_payload.call(payload)]
              end
              error       = job.fetch(:error, nil)

              shard = id_to_shard id

              redis.zadd @keys.all_ids_lex_zset, 0, id
              redis.zadd @keys.all_ids_scored_by_perform_in_zset, perform_in, id
              redis.zadd @keys.all_ids_scored_by_retry_count_zset, retry_count, id

              redis.zadd @keys.ids_scored_by_perform_in_zset(shard), perform_in, id
              redis.zadd @keys.payloads_zset(id), payloads, nx: true

              redis.hset @keys.errors_hash, id, error unless error.nil?
            end
          end
        end
      end

      def ack(shard, data, result = nil)
        ids = data.map { |job| job[:id] }
        length = ids.length

        @pool.with do |redis|
          redis.multi do
            redis.del @keys.processing_ids_with_perform_in_hash(shard)
            redis.del @keys.processing_ids_with_retry_count_hash(shard)
            redis.del @keys.processing_errors_hash(shard)
            ids.each do |id|
              redis.del @keys.processing_payloads_zset(id)
            end
            redis.hdel @keys.processing_length_by_shard_hash, shard
            redis.incrby @keys.processed_key, length if result == :success
            redis.incrby @keys.failed_key,    length if result == :fail
          end
        end
      end

      def processing_data(shard)
        @pool.with do |redis|
          ids = redis.hkeys @keys.processing_ids_with_perform_in_hash(shard)
          return [] if ids.empty?

          res = redis.multi do |redis|
            processing_data_pipeline redis, shard, ids
          end

          processing_data_build res, ids
        end
      end

      def push_to_morgue(batch)
        @pool.with do |redis|
          timestamp = @timestamp.call
          redis.multi do
            batch.each do |job|
              id       = job.fetch(:id)
              payloads = job.fetch(:payloads).map do |(payload, score)|
                [score, Lowkiq.dump_payload.call(payload)]
              end
              error    = job.fetch(:error, nil)


              redis.zadd @keys.morgue_all_ids_lex_zset, 0, id
              redis.zadd @keys.morgue_all_ids_scored_by_updated_at_zset, timestamp, id
              redis.zadd @keys.morgue_payloads_zset(id), payloads, nx: true

              redis.hset @keys.morgue_errors_hash, id, error unless error.nil?
            end
          end
        end
      end

      def morgue_delete(ids)
        @pool.with do |redis|
          redis.multi do
            ids.each do |id|
              redis.zrem @keys.morgue_all_ids_lex_zset, id
              redis.zrem @keys.morgue_all_ids_scored_by_updated_at_zset, id
              redis.del  @keys.morgue_payloads_zset(id)
              redis.hdel @keys.morgue_errors_hash, id
            end
          end
        end
      end

      def delete(ids)
        @pool.with do |redis|
          redis.multi do
            ids.each do |id|
              shard = id_to_shard id
              redis.zrem @keys.all_ids_lex_zset, id
              redis.zrem @keys.all_ids_scored_by_perform_in_zset, id
              redis.zrem @keys.all_ids_scored_by_retry_count_zset, id
              redis.zrem @keys.ids_scored_by_perform_in_zset(shard), id
              redis.del  @keys.payloads_zset(id)
              redis.hdel @keys.errors_hash, id
            end
          end
        end
      end

      def shards
        (0...@shards_count)
      end

      private

      def id_to_shard(id)
        Zlib.crc32(id.to_s) % @shards_count
      end

      def processing_data_pipeline(redis, shard, ids)
        redis.hgetall @keys.processing_ids_with_perform_in_hash(shard)
        redis.hgetall @keys.processing_ids_with_retry_count_hash(shard)
        redis.hgetall @keys.processing_errors_hash(shard)

        ids.each do |id|
          redis.zrange @keys.processing_payloads_zset(id), 0, -1, with_scores: true
        end
      end

      def processing_data_build(arr, ids)
        ids_with_perform_in = arr.shift
        ids_with_retry_count = arr.shift
        errors = arr.shift
        payloads = arr

        ids.zip(payloads).map do |(id, payloads)|
          next if payloads.empty?
          {
            id: id,
            perform_in: ids_with_perform_in[id].to_f,
            retry_count: ids_with_retry_count[id].to_f,
            payloads: payloads.map { |(payload, score)| [Lowkiq.load_payload.call(payload), score] },
            error: errors[id]
          }.compact
        end.compact
      end
    end
  end
end
