RSpec.describe Lowkiq::Queue::Queue do

  let(:redis_pool) { ConnectionPool.new(size: 5, timeout: 5) { Redis.new url: ENV['REDIS_URL'] } }
  let(:shards_count) { 1 }
  let(:shard_index) { 0 }

  let(:queue_name) { 'Test' }
  let(:queue) { Lowkiq::Queue::Queue.new redis_pool, queue_name, shards_count }
  let(:queries) { Lowkiq::Queue::Queries.new redis_pool, queue_name }

  before(:each) { redis_pool.with(&:flushdb) }
  before(:each) { redis_pool.with { |r| Lowkiq::Script.load! r } }
  before(:each) { $now = Lowkiq::Utils::Timestamp.now }
  before(:each) do
    allow(Lowkiq::Utils::Timestamp).to receive(:now) { $now }
  end

  describe 'queue #pop' do
    it 'empty' do
      expect( queue.pop(shard_index, limit: 10) ).to be_empty
    end

    it 'pop' do
      queue.push(
        [
          { id: '1', perform_in: $now - 10, payload: 'v1' },
        ]
      )

      expected = {
        id: '1', perform_in: $now - 10, retry_count: -1, payloads: [['v1', $now]]
      }

      expect( queue.pop(shard_index, limit: 10) ).to contain_exactly(expected)
    end

    it 'skip future' do
      queue.push(
        [
          { id: '1', perform_in: $now + 10, payload: 'v1', score: $now },
        ]
      )

      expect( queue.pop(shard_index, limit: 10) ).to be_empty
    end
  end

  describe 'queue #push merge' do
    it 'same payload' do
      queue.push(
        [
          { id: '1', perform_in: $now, payload: "v1", score: $now },
          { id: '1', perform_in: $now, payload: "v1", score: $now + 10 },
        ]
      )

      expected = {
        id: '1', retry_count: -1, perform_in: $now,
        payloads: [['v1', $now]],
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
    end

    it 'payload order' do
      queue.push(
        [
          { id: '1', perform_in: $now, payload: "v2", score: $now + 10 },
          { id: '1', perform_in: $now, payload: "v1", score: $now },
        ]
      )

      expected = {
        id: '1', retry_count: -1, perform_in: $now,
        payloads: [['v1', $now], ['v2', $now + 10]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
    end

    it 'perform_in' do
      queue.push(
        [
          { id: '1', perform_in: $now, payload: "v1", score: $now },
          { id: '1', perform_in: $now + 10, payload: "v1", score: $now },
        ]
      )

      expected = {
        id: '1', retry_count: -1, perform_in: $now,
        payloads: [['v1', $now]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
    end

    it 'retry_count' do
      queue.push(
        [
          { id: '1', retry_count: 0, perform_in: $now, payload: "v1", score: $now },
          { id: '1', perform_in: $now, payload: "v1", score: $now },
        ]
      )

      expected = {
        id: '1', retry_count: 0, perform_in: $now,
        payloads: [['v1', $now]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
    end
  end

  describe 'queue #push_back merge' do
    it 'same payload' do
      queue.push_back(
        [
          { id: '1', retry_count: 0, perform_in: $now, payloads: [["v1", $now]] },
          { id: '1', retry_count: 0, perform_in: $now, payloads: [["v1", $now + 10]] },
        ]
      )

      expected = {
        id: '1', retry_count: 0, perform_in: $now,
        payloads: [['v1', $now]],
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
    end

    it 'payload order' do
      queue.push_back(
        [
          { id: '1', retry_count: 0, perform_in: $now, payloads: [["v2", $now + 10]] },
          { id: '1', retry_count: 0, perform_in: $now, payloads: [["v1", $now]] },
        ]
      )

      expected = {
        id: '1', retry_count: 0, perform_in: $now,
        payloads: [['v1', $now], ['v2', $now + 10]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
    end

    it 'perform_in' do
      queue.push_back(
        [
          { id: '1', perform_in: $now, payloads: [["v1", $now]] },
          { id: '1', perform_in: $now + 10, payloads: [["v1", $now]] },
        ]
      )

      expected = {
        id: '1', retry_count: -1, perform_in: $now + 10,
        payloads: [['v1', $now]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
    end

    it 'retry_count' do
      queue.push_back(
        [
          { id: '1', retry_count: 0, perform_in: $now, payloads: [["v1", $now]] },
          { id: '1', retry_count: 1, perform_in: $now, payloads: [["v1", $now]] },
        ]
      )

      expected = {
        id: '1', retry_count: 1, perform_in: $now,
        payloads: [['v1', $now]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
    end

    it 'error' do
      error = "some error"
      queue.push_back(
        [
          { id: '1', payloads: [['v1', $now]], error: error },
        ]
      )

      expect( queries.fetch(['1']).first[:error] ).to eq(error)
    end
  end

  it '#processing_data' do
    queue.push(
      [
        { id: '1', perform_in: $now - 10, payload: 'v1', score: $now },
      ]
    )

    queue.pop(shard_index, limit: 10)

    expected = {
      id: '1', perform_in: $now - 10, retry_count: -1, payloads: [['v1', $now]]
    }

    expect( queue.processing_data(shard_index) ).to contain_exactly(expected)
  end

  describe '#ack' do
    before(:each) do
      queue.push(
        [
          { id: '1', perform_in: $now - 10, payload: 'v1', score: $now },
        ]
      )
    end
    let!(:data) { queue.pop shard_index, limit: 10 }

    it '#processing_data' do
      expect { queue.ack shard_index, data }.to change { queue.processing_data(shard_index) }.to([])
    end
  end

  describe '#push_to_morgue' do
    it 'error' do
      error = "some error"
      queue.push_to_morgue(
        [
          { id: '1', payloads: [['v1', $now]], error: error },
        ]
      )

      expect( queries.morgue_fetch(['1']).first[:error] ).to eq(error)
    end
  end

  describe 'serialization' do
    let(:payload) { { num: 1, str: 'str', time: Time.now, arr: [1, 2, 3] } }
    before(:each) do
      queue.push(
        [
          { id: '1', payload: payload },
        ]
      )
    end

    it '#fetch' do
      expect( queries.fetch(['1']).first[:payloads].first.first ).to eq(payload)
    end
  end

  it '#morgue_delete' do
    queue.push_to_morgue(
      [
        { id: '1', payloads: [["v1", $now]] },
      ]
    )

    queue.morgue_delete(['1'])

    expect( queries.morgue_fetch ['1'] ).to be_empty
  end

  it '#delete' do
    queue.push(
      [
        { id: '1' },
      ]
    )

    queue.delete(['1'])

    expect( queries.fetch ['1'] ).to be_empty
  end
end
