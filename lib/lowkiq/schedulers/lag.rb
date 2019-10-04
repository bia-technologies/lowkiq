module Lowkiq
  module Schedulers
    class Lag
      def initialize(wait, metrics)
        @metrics = metrics
        @wait = wait
      end

      def build_job(shard_handlers)
        Proc.new do
          identifiers = shard_handlers.map { |sh| { queue_name: sh.queue_name, shard: sh.shard_index } }
          metrics = @metrics.call identifiers
          shard_handler, _lag =
                         shard_handlers.zip(metrics.map(&:lag))
                           .select { |(_, lag)| lag > 0 }
                           .max_by { |(_, lag)| lag }

          if shard_handler
            shard_handler.process
          else
            @wait.call
          end
        end
      end
    end
  end
end
