require 'bundler/setup'
Bundler.require(:default)
require 'sidekiq/api'

Sidekiq.configure_server do |config|
  config.options[:concurrency] = 5
  config.logger.level = Logger::ERROR
end

$jobs_count = 100_000

class Worker
  include Sidekiq::Worker

  def perform(arg)
  end
end

Sidekiq.redis {|c| c.flushdb}

jobs = (0...$jobs_count).map do |i|
  [i.to_s]
end

Sidekiq::Client.push_bulk('class' => Worker, 'args' => jobs)

puts "jobs are enqueued"

start = Time.now.to_i

Monitoring = Thread.new do
  loop do
    len = Sidekiq::Queue.new.size
    puts len

    if len == 0
      total = Time.now.to_i - start

      puts "total time: #{total}"

      exit 0
    end

    sleep 1
  end
end
