module Lowkiq
  class Server
    def self.build(options)
      require options[:require]
      Lowkiq.on_server_init.call

      splitter = Lowkiq.build_splitter.call
      shard_handlers_by_thread = splitter.call Lowkiq.shard_handlers
      scheduler = Lowkiq.build_scheduler.call
      new shard_handlers_by_thread, scheduler
    end

    def initialize(shard_handlers_by_thread, scheduler)
      @shard_handlers_by_thread = shard_handlers_by_thread
      @scheduler = scheduler
      @threads = []
    end

    def start
      @shard_handlers_by_thread.each do |handlers|
        handlers.each(&:restore)
      end

      @threads = @shard_handlers_by_thread.map do |handlers|
        job = @scheduler.build_job handlers
        Thread.new do
          job.call until exit_from_thread?
        end
      end
    end

    def stop
      @stopped = true
    end

    def join
      @threads.each(&:join)
    end

    def exit_from_thread?
      stopped? || failed?
    end

    def stopped?
      @stopped
    end

    def failed?
      @threads.map(&:status).any? do |status|
        status != "run" && status != "sleep"
      end
    end
  end
end
