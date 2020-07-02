RSpec.describe Lowkiq::Queue::ShardMetrics do
  let(:redis_pool) { ConnectionPool.new(size: 5, timeout: 5) { Redis.new url: ENV['REDIS_URL'] } }
  let(:shards_count) { 1 }
  let(:shard_index) { 0 }

  let(:queue_name) { 'Test' }
  let(:queue) { Lowkiq::Queue::Queue.new redis_pool, queue_name, shards_count }
  let(:shard_metrics) do
    Lowkiq::Queue::ShardMetrics
      .new(redis_pool)
      .call([{queue_name: queue_name, shard: shard_index}])
      .first
  end

  before(:each) { redis_pool.with(&:flushdb) }
  before(:each) { redis_pool.with { |r| Lowkiq::Script.load! r } }
  before(:each) { $now = Lowkiq::Utils::Timestamp.now }
  before(:each) do
    allow(Lowkiq::Utils::Timestamp).to receive(:now) { $now }
  end

  describe 'shard_metrics' do
    describe 'empty' do
      it 'lag' do
        expect( shard_metrics.lag ).to be(0)
      end
    end

    describe 'filled' do
      it 'lag' do
        lag = 10
        queue.push(
          [
            { id: '1', perform_in: $now - lag, payload: 'v1' },
            { id: '2', perform_in: $now,       payload: 'v1' },
          ]
        )

        expect( shard_metrics.lag ).to be(lag)
      end
    end
  end
end
