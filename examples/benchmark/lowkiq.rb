# require 'bundler/setup'
# Bundler.require(:default)

$jobs_count = 100_000

Lowkiq.build_scheduler = ->() { Lowkiq.build_seq_scheduler }
Lowkiq.redis = ->() { Redis.new url: ENV.fetch('REDIS_URL'), driver: :hiredis }

module Worker
  extend Lowkiq::Worker

  # self.shards_count = 50

  def self.perform(payloads_by_id)
  end
end

Lowkiq.server_redis_pool.with do |redis|
  redis.flushdb
end

jobs = (0...$jobs_count).map do |i|
  { id: i, payload: i.to_s }
end
jobs.each_slice(10_000) do |batch|
  Worker.perform_async batch
end

puts "jobs are enqueued"

start = Time.now.to_f

Monitoring = Thread.new do
  metrics = Lowkiq::Queue::QueueMetrics.new Lowkiq.client_redis_pool

  loop do
    len = metrics.call([Worker.queue_name]).first.length
    puts len

    if len == 0
      total = Time.now.to_f - start

      puts "total time: #{total}"

      exit 0
    end

    sleep 1
  end
end
