RSpec.describe Lowkiq::Queue::QueueMetrics do
  let(:redis_pool) { ConnectionPool.new(size: 5, timeout: 5) { Redis.new url: ENV['REDIS_URL'] } }
  let(:shards_count) { 1 }
  let(:shard_index) { 0 }

  let(:queue_name) { 'Test' }
  let(:queue) { Lowkiq::Queue::Queue.new redis_pool, queue_name, shards_count }
  let(:queue_metrics) do
    Lowkiq::Queue::QueueMetrics
      .new(redis_pool)
      .call([queue_name])
      .first
  end

  before(:each) { redis_pool.with(&:flushdb) }
  before(:each) { redis_pool.with { |r| Lowkiq::Script.load! r } }
  before(:each) { $now = Lowkiq::Utils::Timestamp.now }
  before(:each) do
    allow(Lowkiq::Utils::Timestamp).to receive(:now) { $now }
  end

  describe 'queue_metrics' do
    describe 'empty' do
      it "length" do
        expect( queue_metrics.length ).to be(0)
      end

      it "morgue_length" do
        expect( queue_metrics.morgue_length ).to be(0)
      end

      it 'lag' do
        expect( queue_metrics.lag ).to be(0)
      end

      it 'processed' do
        expect( queue_metrics.processed ).to be(0)
      end

      it 'failed' do
        expect( queue_metrics.failed ).to be(0)
      end

      it 'busy' do
        expect( queue_metrics.busy ).to be(0)
      end
    end

    describe 'filled' do
      it 'length' do
        queue.push(
          [
            { id: '0', payload: "v1" },
          ]
        )

        expect( queue_metrics.length ).to be(1)
      end

      it 'mougue_length' do
        queue.push_to_morgue(
          [
            { id: '1', payloads: [['v1', $now]] },
          ]
        )

        expect( queue_metrics.morgue_length ).to be(1)
      end

      it 'lag' do
        lag = 10.0
        queue.push(
          [
            { id: '1', perform_in: $now - lag, payload: 'v1' },
            { id: '2', perform_in: $now,       payload: 'v1' },
          ]
        )

        expect( queue_metrics.lag ).to be(lag)
      end

      it 'lag for not ready' do
        queue.push(
          [
            { id: '1', perform_in: $now + 10, payload: 'v1' },
          ]
        )

        expect( queue_metrics.lag ).to be(0)
      end

      it 'processed' do
        queue.push(
          [
            { id: '1', payload: 'v1' },
          ]
        )
        data = queue.pop shard_index, limit: 10
        queue.ack shard_index, data, :success

        expect( queue_metrics.processed ).to be(1)
      end

      it 'failed' do
        queue.push(
          [
            { id: '1', payload: 'v1' },
          ]
        )
        data = queue.pop shard_index, limit: 10
        queue.ack shard_index, data, :fail

        expect( queue_metrics.failed ).to be(1)
      end

      it 'busy' do
        queue.push(
          [
            { id: '1', payload: 'v1' },
          ]
        )
        queue.pop shard_index, limit: 10

        expect( queue_metrics.busy ).to be(1)
      end
    end
  end
end
