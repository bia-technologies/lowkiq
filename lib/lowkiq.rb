require "connection_pool"
require "redis"
require "zlib"
require "base64"
require "json"
require "ostruct"
require "optparse"
require "digest"

require "lowkiq/version"
require "lowkiq/utils"
require "lowkiq/script"

require "lowkiq/option_parser"

require "lowkiq/splitters/default"
require "lowkiq/splitters/by_node"

require "lowkiq/schedulers/lag"
require "lowkiq/schedulers/seq"

require "lowkiq/server"

require "lowkiq/queue/keys"
require "lowkiq/queue/fetch"
require "lowkiq/queue/queue"
require "lowkiq/queue/queue_metrics"
require "lowkiq/queue/shard_metrics"
require "lowkiq/queue/queries"
require "lowkiq/queue/actions"
require "lowkiq/worker"
require "lowkiq/shard_handler"

require "lowkiq/redis_info"

require "lowkiq/web"

module Lowkiq
  class << self
    attr_accessor :poll_interval, :threads_per_node,
                  :redis, :client_pool_size, :pool_timeout,
                  :server_middlewares, :on_server_init,
                  :build_scheduler, :build_splitter,
                  :last_words,
                  :dump_payload, :load_payload,
                  :workers, :format_error_message

    def server_redis_pool
      @server_redis_pool ||= ConnectionPool.new(size: threads_per_node, timeout: pool_timeout, &redis)
    end

    def client_redis_pool
      @client_redis_pool ||= ConnectionPool.new(size: client_pool_size, timeout: pool_timeout, &redis)
    end

    def server_wrapper
      null = -> (worker, batch, &block) { block.call }
      server_middlewares.reduce(null) do |wrapper, m|
        -> (worker, batch, &block) do
          wrapper.call worker, batch do
            m.call worker, batch, &block
          end
        end
      end
    end

    def shard_handlers
      self.workers.flat_map do |w|
        ShardHandler.build_many w, self.server_wrapper
      end
    end

    def build_lag_scheduler
      Schedulers::Lag.new(
        ->() { sleep Lowkiq.poll_interval },
        Queue::ShardMetrics.new(self.server_redis_pool)
      )
    end

    def build_seq_scheduler
      Schedulers::Seq.new(
        ->() { sleep Lowkiq.poll_interval }
      )
    end

    def build_default_splitter
      Lowkiq::Splitters::Default.new Lowkiq.threads_per_node
    end

    def build_by_node_splitter(number_of_nodes, node_number)
      Lowkiq::Splitters::ByNode.new(
        number_of_nodes,
        node_number,
        Lowkiq.threads_per_node,
      )
    end

    def compress_error(error_msg)
      compressed = Zlib::Deflate.deflate(error_msg.to_s)
      Base64.encode64(compressed)
    end

    def uncompress_error(error_msg)
      return error_msg unless compressed?(error_msg)
      decoded = Base64.decode64(error_msg)
      Zlib::Inflate.inflate(decoded)
    end

    private

    # checking whether error message is base64 encoded for backward compatibility
    def compressed?(error_msg)
      error_msg.is_a?(String) && Base64.encode64(Base64.decode64(error_msg)) == error_msg
    end
  end

  # defaults
  self.poll_interval = 1
  self.threads_per_node = 5
  self.redis = ->() { Redis.new url: ENV.fetch('REDIS_URL') }
  self.client_pool_size = 5
  self.pool_timeout = 5
  self.server_middlewares = []
  self.on_server_init = ->() {}
  self.build_scheduler = ->() { Lowkiq.build_lag_scheduler }
  self.build_splitter = ->() { Lowkiq.build_default_splitter }
  self.last_words = ->(ex) {}
  self.dump_payload = ::Marshal.method :dump
  self.load_payload = ::Marshal.method :load
  self.workers = []
  self.format_error_message = :message.to_proc
end
