module Lowkiq
  module Schedulers
    class Seq
      def initialize(wait)
        @wait = wait
      end

      def build_job(shard_handlers)
        shard_enumerator = shard_handlers.cycle
        processed = []

        lambda do
          if processed.length == shard_handlers.length
            all_failed = processed.all? { |ok| !ok }
            processed.clear
            if all_failed
              @wait.call
              return
            end
          end

          shard_handler = shard_enumerator.next
          processed << shard_handler.process
        end
      end
    end
  end
end
