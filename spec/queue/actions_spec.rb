RSpec.describe Lowkiq::Queue::Actions do

  let(:redis_pool) { ConnectionPool.new(size: 5, timeout: 5) { Redis.new url: ENV['REDIS_URL'] } }
  let(:shards_count) { 1 }
  let(:shard_index) { 0 }

  let(:queue_name) { 'Test' }

  let(:queue) { Lowkiq::Queue::Queue.new redis_pool, queue_name, shards_count }
  let(:queries) { Lowkiq::Queue::Queries.new redis_pool, queue_name }
  let(:actions) { Lowkiq::Queue::Actions.new queue, queries }

  before(:each) { redis_pool.with(&:flushdb) }
  before(:each) { redis_pool.with { |r| Lowkiq::Script.load! r } }
  before(:each) { $now = Lowkiq::Utils::Timestamp.now }
  before(:each) do
    allow(Lowkiq::Utils::Timestamp).to receive(:now) { $now }
  end

  describe '#perform_all_jobs_now' do
    it 'empty' do
      expect { actions.perform_all_jobs_now }.to_not raise_error
    end

    it 'reset' do
      queue.push [ { id: '1'} ]

      expect {
        actions.perform_all_jobs_now
      }.to change {
        queries.fetch(['1']).first[:perform_in]
      }.to(0)
    end
  end

  describe '#kill_all_failed_jobs' do
    it 'empty' do
      expect { actions.kill_all_failed_jobs }.to_not raise_error
    end

    it 'kill' do
      queue.push(
        [
          { id: '1' },
          { id: '2', retry_count: 0 },
        ]
      )

      actions.kill_all_failed_jobs

      expect( queries.fetch(['1']) ).to_not be_empty
      expect( queries.fetch(['2']) ).to be_empty

      expect( queries.morgue_fetch(['1']) ).to be_empty
      expect( queries.morgue_fetch(['2']) ).to_not be_empty
    end
  end

  describe '#delete_all_failed_jobs' do
    it 'empty' do
      expect { actions.delete_all_failed_jobs }.to_not raise_error
    end

    it 'delete' do
      queue.push(
        [
          { id: '1' },
          { id: '2', retry_count: 0 },
        ]
      )

      actions.delete_all_failed_jobs

      expect( queries.fetch(['1']) ).to_not be_empty
      expect( queries.fetch(['2']) ).to be_empty

      expect( queries.morgue_fetch(['1']) ).to be_empty
      expect( queries.morgue_fetch(['2']) ).to be_empty
    end
  end

  describe '#morgue_queue_up' do
    it 'empty queue' do
      queue.push_to_morgue(
        [
          { id: '1', payloads: [['v1', $now]] },
        ]
      )

      actions.morgue_queue_up ['1']

      expected = {
        id: '1', perform_in: $now, retry_count: -1, payloads: [['v1', $now]],
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
      expect( queries.morgue_fetch ['1'] ).to be_empty
    end

    # несколько странный случай, но все же
    # странный, т.к. в морге не должна оказаться payload с бОльшим score
    it 'same payload' do
      queue.push(
        [
          { id: '1', retry_count: -1, perform_in: $now, payload: "v1", score: $now },
        ]
      )

      queue.push_to_morgue(
        [
          { id: '1', payloads: [["v1", $now + 10]] },
        ]
      )

      actions.morgue_queue_up ['1']

      expected = {
        id: '1', retry_count: -1, perform_in: $now, payloads: [['v1', $now]],
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
      expect( queries.morgue_fetch ['1'] ).to be_empty
    end

    it 'payload order' do
      queue.push(
        [
          { id: '1', retry_count: -1, perform_in: $now, payload: "v2", score: $now + 10 },
        ]
      )

      queue.push_to_morgue(
        [
          { id: '1', payloads: [["v1", $now]] },
        ]
      )

      actions.morgue_queue_up ['1']

      expected = {
        id: '1', retry_count: -1, perform_in: $now,
        payloads: [['v1', $now], ['v2', $now + 10]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
      expect( queries.morgue_fetch ['1'] ).to be_empty
    end

    it 'perform_in' do
      queue.push(
        [
          { id: '1', retry_count: -1, perform_in: $now + 10, payload: "v1", score: $now },
        ]
      )

      queue.push_to_morgue(
        [
          { id: '1', payloads: [["v1", $now]] },
        ]
      )

      actions.morgue_queue_up ['1']

      expected = {
        id: '1', retry_count: -1, perform_in: $now,
        payloads: [['v1', $now]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
      expect( queries.morgue_fetch ['1'] ).to be_empty
    end

    it 'retry_count' do
      queue.push(
        [
          { id: '1', retry_count: 0, perform_in: $now, payload: "v1", score: $now },
        ]
      )

      queue.push_to_morgue(
        [
          { id: '1', payloads: [["v1", $now]] },
        ]
      )

      actions.morgue_queue_up ['1']

      expected = {
        id: '1', retry_count: -1, perform_in: $now, payloads: [['v1', $now]]
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected)
      expect( queries.morgue_fetch ['1'] ).to be_empty
    end
  end

  it '#morgue_queue_up_all_jobs' do
    queue.push_to_morgue(
      [
        { id: '1', payloads: [["v1", $now]] },
      ]
    )

    actions.morgue_queue_up_all_jobs

    expect( queries.morgue_fetch ['1'] ).to be_empty
    expect( queries.fetch ['1'] ).to_not be_empty
  end

  it '#morgue_delete_all_jobs' do
    queue.push_to_morgue(
      [
        { id: '1', payloads: [["v1", $now]] },
      ]
    )

    actions.morgue_delete_all_jobs

    expect( queries.morgue_fetch ['1'] ).to be_empty
  end
end
