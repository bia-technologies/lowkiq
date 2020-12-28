require 'logger'

# Lowkiq.build_splitter = ->() { Lowkiq.build_by_node_splitter 2, 0 }

$logger = Logger.new(STDOUT)

Lowkiq.server_middlewares << -> (worker, batch, &block) do
  $logger.info "Started job for #{worker} #{batch}"
  block.call
  $logger.info "Finished job for #{worker} #{batch}"
end

Lowkiq.server_middlewares << -> (worker, batch, &block) do
  begin
    block.call
  rescue => e
    $logger.error "#{e.message} #{worker} #{batch}"
    raise e
  end
end

Lowkiq.last_words = ->(ex) { puts ex }

module ATestWorker
  extend Lowkiq::Worker

  self.max_retry_count = 2
  def self.perform_async(jobs)
    jobs.each do |job|
      job.merge! id: job[:payload][:id]
    end
    super
  end

  def self.perform(batch)
    sleep Random.rand

    if Random.rand(5) == 0
      fail "error"
    end
  end
end

module ATest2Worker
  extend Lowkiq::Worker

  self.max_retry_count = 2
  def self.perform_async(jobs)
    jobs.each do |job|
      job.merge! id: job[:payload][:id]
    end
    super
  end

  def self.perform(batch)
    sleep Random.rand

    if Random.rand(5) == 0
      fail "error"
    end
  end
end

Lowkiq.workers = [ ATestWorker, ATest2Worker ]

ATestWorker.perform_async  1000.times.map { |id| { payload: {id: id},
                                                   perform_in: Time.now.to_i + Random.rand(10)} }
ATest2Worker.perform_async 1000.times.map { |id| { payload: {id: id},
                                                   perform_in: Time.now.to_i + Random.rand(10)} }

require 'rack'

Thread.new do
  Rack::Handler::WEBrick.run Lowkiq::Web, Port: 8080, Host: '0.0.0.0'
end
