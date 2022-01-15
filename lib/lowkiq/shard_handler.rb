module Lowkiq
  class ShardHandler
    def self.build_many(worker, wrapper)
      (0...worker.shards_count).map do |shard_index|
        new shard_index, worker, wrapper
      end
    end

    attr_reader :shard_index, :queue_name, :worker

    def initialize(shard_index, worker, wrapper)
      @shard_index = shard_index
      @queue_name = worker.queue_name
      @worker = worker
      @wrapper = wrapper
      @timestamp = Utils::Timestamp.method(:now)
      @queue = Queue::Queue.new Lowkiq.server_redis_pool,
                                worker.queue_name,
                                worker.shards_count
    end

    def process
      data = @queue.pop @shard_index, limit: @worker.batch_size

      return false if data.empty?

      begin
        batch = batch_from_data data

        @wrapper.call @worker, batch do
          @worker.perform batch
        end

        @queue.ack @shard_index, data, :success
        true
      rescue => ex
        fail! data, ex
        back, morgue = separate data

        @queue.push_back back
        @queue.push_to_morgue morgue
        @queue.ack @shard_index, data, :fail
        false
      end
    end

    def restore
      data = @queue.processing_data @shard_index
      return if data.nil?
      @queue.push_back data
      @queue.ack @shard_index, data
    end

    private

    def batch_from_data(data)
      data.each_with_object({}) do |job, h|
        id = job.fetch(:id)
        payloads = job.fetch(:payloads).map(&:first)
        h[id] = payloads
      end
    end

    def fail!(data, ex)
      data.map! do |job|
        job[:retry_count] += 1
        job[:perform_in] = @timestamp.call + @worker.retry_in(job[:retry_count])
        job[:error] = Lowkiq.format_error.call(ex)
        job
      end
    end

    def separate(data)
      back = []
      morgue = []

      data.each do |job|
        id          = job.fetch(:id)
        payloads    = job.fetch(:payloads)
        retry_count = job.fetch(:retry_count)
        perform_in  = job.fetch(:perform_in)
        error       = job.fetch(:error, nil)

        morgue_payload = payloads.shift if retry_count >= @worker.max_retry_count

        if payloads.any?
          job = {
            id: id,
            payloads: payloads,
            retry_count: morgue_payload ? 0 : retry_count,
            perform_in:  morgue_payload ? @timestamp.call : perform_in,
            error: error,
          }.compact
          back << job
        end

        if morgue_payload
          job = {
            id: id,
            payloads: [morgue_payload],
            error: error,
          }.compact
          morgue << job
        end
      end

      [back, morgue]
    end
  end
end
