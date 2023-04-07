module Lowkiq
  module Queue
    class Actions
      def initialize(queue, queries)
        @queue = queue
        @queries = queries

        @pool = queue.pool
        @keys = Keys.new queue.name
      end

      def perform_all_jobs_now
        @pool.with do |redis|
          uredis = Utils::Redis.new redis
          redis.multi do |pipeline|
            uredis.zresetscores @keys.all_ids_scored_by_perform_in_zset
            @queue.shards.each do |shard|
              uredis.zresetscores @keys.ids_scored_by_perform_in_zset(shard)
            end
          end
        end
      end

      def kill_all_failed_jobs
        until (jobs = @queries.range_by_retry_count('0', '+inf', limit: 100); jobs.empty?)
          @queue.push_to_morgue jobs
          ids = jobs.map { |j| j[:id] }
          @queue.delete ids
        end
      end

      def delete_all_failed_jobs
        until (jobs = @queries.range_by_retry_count('0', '+inf', limit: 100); jobs.empty?)
          ids = jobs.map { |j| j[:id] }
          @queue.delete ids
        end
      end

      def morgue_queue_up(ids)
        jobs = @queries.morgue_fetch ids
        return if jobs.empty?

        @queue.push_back jobs
        @queue.morgue_delete ids
      end

      def morgue_queue_up_all_jobs
        until (jobs = @queries.morgue_range_by_id('-', '+', limit: 100); jobs.empty?)
          @queue.push_back jobs
          ids = jobs.map { |j| j[:id] }
          @queue.morgue_delete ids
        end
      end

      def morgue_delete_all_jobs
        until (jobs = @queries.morgue_range_by_id('-', '+', limit: 100); jobs.empty?)
          ids = jobs.map { |j| j[:id] }
          @queue.morgue_delete ids
        end
      end
    end
  end
end
