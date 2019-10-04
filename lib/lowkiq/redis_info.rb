module Lowkiq
  class RedisInfo
    def initialize(redis_pool)
      @redis_pool = redis_pool
    end

    def call
      @redis_pool.with do |redis|
        info = redis.info
        {
          url: redis.connection[:id],
          version: info["redis_version"],
          uptime_in_days: info["uptime_in_days"],
          connected_clients: info["connected_clients"],
          used_memory_human: info["used_memory_human"],
          used_memory_peak_human: info["used_memory_peak_human"],
        }
      end
    end
  end
end
