module Lowkiq
  module Worker
    attr_accessor :shards_count,
                  :batch_size,
                  :max_retry_count,
                  :queue_name,

                  def self.extended(mod)
                    super
                    mod.shards_count = 5
                    mod.batch_size = 1
                    mod.max_retry_count = 25
                    mod.queue_name = mod.name
                  end

    # i.e. 15, 16, 31, 96, 271, ... seconds + a random amount of time
    def retry_in(retry_count)
      (retry_count ** 4) + 15 + (rand(30) * (retry_count + 1))
    end

    def perform(payload)
      fail "not implemented"
    end

    def client_queue
      Queue::Queue.new Lowkiq.client_redis_pool, self.queue_name, self.shards_count
    end

    def client_queries
      Queue::Queries.new Lowkiq.client_redis_pool, self.queue_name
    end

    def client_actions
      Queue::Actions.new client_queue, client_queries
    end

    def perform_async(batch)
      client_queue.push batch
    end
  end
end
