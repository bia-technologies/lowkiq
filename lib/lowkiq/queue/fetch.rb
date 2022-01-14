module Lowkiq
  module Queue
    class Fetch
      def initialize(name)
        @keys = Keys.new name
      end

      def fetch(redis, strategy, ids)
        resp = redis.public_send strategy do
          ids.each do |id|
            redis.zscore @keys.all_ids_scored_by_perform_in_zset, id
            redis.zscore @keys.all_ids_scored_by_retry_count_zset, id
            redis.zrange @keys.payloads_zset(id), 0, -1, with_scores: true
            redis.hget   @keys.errors_hash, id
          end
        end

        ids.zip(resp.each_slice(4)).map do |x|
          next if x[1][0].nil? # пропускаем id, если его уже нет в очереди
          res = {
            id: x[0],
            perform_in: x[1][0],
            retry_count: x[1][1],
            payloads: x[1][2].map { |(payload, score)| [Lowkiq.load_payload.call(payload), score] },
            error: Lowkiq.uncompress_error(x[1][3]),
          }.compact
        end.compact
      end

      def morgue_fetch(redis, strategy, ids)
        resp = redis.public_send strategy do
          ids.each do |id|
            redis.zscore @keys.morgue_all_ids_scored_by_updated_at_zset, id
            redis.zrange @keys.morgue_payloads_zset(id), 0, -1, with_scores: true
            redis.hget   @keys.morgue_errors_hash, id
          end
        end

        ids.zip(resp.each_slice(3)).map do |x|
          next if x[1][0].nil? # пропускаем id, если его уже нет в очереди
          {
            id: x[0],
            updated_at: x[1][0],
            payloads: x[1][1].map { |(payload, score)| [Lowkiq.load_payload.call(payload), score] },
            error: Lowkiq.uncompress_error(x[1][2]),
          }.compact
        end.compact
      end
    end
  end
end
