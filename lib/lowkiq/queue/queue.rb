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
              redis.zadd @keys.payloads_zset(id), score, Marshal.dump_payload(payload), nx: true
            end
          end
        end
      end

      def pop(shard, limit:)
        @pool.with do |redis|
          data = nil
          ids = redis.zrangebyscore @keys.ids_scored_by_perform_in_zset(shard),
                                    0, @timestamp.call,
                                    limit: [0, limit]
          return [] if ids.empty?

          payloads_keys = ids.map { |id| @keys.payloads_zset id }
          tx = redis.watch *payloads_keys do
            data = @fetch.fetch(redis, :multi, ids)

            redis.multi do
              _delete redis, ids
              redis.set  @keys.processing_key(shard), Marshal.dump_data(data)
              redis.hset @keys.processing_length_by_shard_hash, shard, data.length
            end
          end until tx

          data
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
                [score, Marshal.dump_payload(payload)]
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
        length = data.length

        @pool.with do |redis|
          redis.multi do
            redis.del  @keys.processing_key(shard)
            redis.hdel @keys.processing_length_by_shard_hash, shard

            redis.incrby @keys.processed_key, length if result == :success
            redis.incrby @keys.failed_key, length    if result == :fail
          end
        end
      end

      def processing_data(shard)
        data = @pool.with do |redis|
          redis.get @keys.processing_key(shard)
        end
        return [] if data.nil?

        Marshal.load_data data
      end

      def push_to_morgue(batch)
        @pool.with do |redis|
          timestamp = @timestamp.call
          redis.multi do
            batch.each do |job|
              id       = job.fetch(:id)
              payloads = job.fetch(:payloads).map do |(payload, score)|
                [score, Marshal.dump_payload(payload)]
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
            _delete redis, ids
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

      def _delete(redis, ids)
        redis.zrem @keys.all_ids_lex_zset, ids
        redis.zrem @keys.all_ids_scored_by_perform_in_zset, ids
        redis.zrem @keys.all_ids_scored_by_retry_count_zset, ids
        redis.hdel @keys.errors_hash, ids

        ids.each do |id|
          shard = id_to_shard id
          redis.zrem @keys.ids_scored_by_perform_in_zset(shard), id
          redis.del  @keys.payloads_zset(id)
        end
      end
    end
  end
end
