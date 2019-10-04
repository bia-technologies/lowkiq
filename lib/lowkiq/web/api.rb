module Lowkiq
  module Web
    module Api
      GET = 'GET'.freeze
      POST = 'POST'.freeze

      ACTIONS = [
        Action.new(GET, ['v1', 'stats']) do |_, _|
          worker_names = Lowkiq.workers.map(&:name)
          queue_names = Lowkiq.workers.map(&:queue_name)

          metrics = Lowkiq::Queue::QueueMetrics
                      .new(Lowkiq.client_redis_pool)
                      .call(queue_names)
          by_worker = worker_names.zip(metrics).each_with_object({}) do |(name, m), o|
            o[name] = m.to_h.slice(:length, :morgue_length, :lag)
          end
          total = {
            length:        metrics.map(&:length).reduce(&:+).to_i,
            morgue_length: metrics.map(&:morgue_length).reduce(&:+).to_i,
            lag:           metrics.map(&:lag).max.to_i,
          }
          {
            total: total,
            by_worker: by_worker,
          }
        end,

        Action.new(GET, ['web', 'dashboard']) do |_, _|
          worker_names = Lowkiq.workers.map(&:name)
          queue_names = Lowkiq.workers.map(&:queue_name)

          metrics = Lowkiq::Queue::QueueMetrics
                      .new(Lowkiq.client_redis_pool)
                      .call(queue_names)

          queues = worker_names.zip(metrics).map do |(name, m)|
            {
              name: name,
              lag: m.lag,
              processed: m.processed,
              failed: m.failed,
              busy: m.busy,
              enqueued: m.length, # fresh + retries
              fresh: m.fresh,
              retries: m.retries,
              dead: m.morgue_length,
            }
          end

          redis_info = Lowkiq::RedisInfo.new(Lowkiq.client_redis_pool).call

          {
            queues: queues,
            redis_info: redis_info,
          }
        end,

        %w[ range_by_id range_by_perform_in range_by_retry_count
            morgue_range_by_id morgue_range_by_updated_at
        ].map do |method|
          Action.new(GET, ['web', :worker, method]) do |req, match|
            min = req.params['min']
            max = req.params['max']

            queries = match_to_worker(match).client_queries
            queries.public_send method, min, max, limit: 100
          end
        end,

        %w[ rev_range_by_id rev_range_by_perform_in rev_range_by_retry_count
            morgue_rev_range_by_id morgue_rev_range_by_updated_at
        ].map do |method|
          Action.new(GET, ['web', :worker, method]) do |req, match|
            min = req.params['min']
            max = req.params['max']

            queries = match_to_worker(match).client_queries
            queries.public_send method, max, min, limit: 100
          end
        end,

        Action.new(GET, ['web', :worker, 'processing_data']) do |_, match|
          queue = match_to_worker(match).client_queue

          queue.shards.flat_map do |shard|
            queue.processing_data shard
          end
        end,

        %w[ morgue_delete ].map do |method|
          Action.new(POST, ['web', :worker, method]) do |req, match|
            ids = req.params['ids']
            Thread.new do
              queue = match_to_worker(match).client_queue
              queue.public_send method, ids
            end
            :ok
          end
        end,

        %w[ morgue_queue_up ].map do |method|
          Action.new(POST, ['web', :worker, method]) do |req, match|
            ids = req.params['ids']
            Thread.new do
              actions = match_to_worker(match).client_actions
              actions.public_send method, ids
            end
            :ok
          end
        end,

        %w[ morgue_queue_up_all_jobs morgue_delete_all_jobs
            perform_all_jobs_now kill_all_failed_jobs delete_all_failed_jobs].map do |method|
          Action.new(POST, ['web', :worker, method]) do |_, match|
            Thread.new do
              actions = match_to_worker(match).client_actions
              actions.public_send method
            end
            :ok
          end
        end,

      ].flatten

      def self.match_to_worker(match)
        Lowkiq.workers.find { |w| w.name == match[:worker] }
      end

      def self.call(env)
        req = Rack::Request.new env

        ACTIONS.each do |action|
          resp = action.call req
          return resp if resp
        end

        [404, {}, ["not found"]]
      end
    end
  end
end
