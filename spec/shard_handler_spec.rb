RSpec.describe Lowkiq::ShardHandler do
  module ATestWorker
    extend Lowkiq::Worker

    self.shards_count = 1

    def self.retry_in(count)
      $retry_in.call(count)
    end

    def self.perform(batch)
      $perform.call(batch)
    end
  end

  before(:each) { Lowkiq.server_redis_pool.with(&:flushdb)  }
  before(:each) { Lowkiq.server_redis_pool.with { |r| Lowkiq::Script.load! r } }

  before(:each) { $now = Lowkiq::Utils::Timestamp.now }
  before(:each) do
    allow(Lowkiq::Utils::Timestamp).to receive(:now) { $now }
  end

  before(:each) { $id = double('id') }
  before(:each) { $retry_in = double('retry_in') }
  before(:each) { $perform = double('perform') }

  let(:worker) { ATestWorker }
  let(:queue) { worker.client_queue }
  let(:queries) { worker.client_queries }
  let(:wrapper) { -> (worker, batch, &block) { block.call } }
  let(:shards) { described_class.build_many worker, wrapper }
  let(:shard_index) { 0 }
  let(:shard) { shards[shard_index] }

  context '#process' do
    it 'normal' do
      payload = "payload"

      expect($retry_in).to_not receive(:call)
      expect($perform).to receive(:call).with({ '1' => [payload] })

      worker.perform_async(
        [
          { id: 1, payload: payload },
        ]
      )

      expect( shard.process ).to be(true)
      expect( queries.fetch ['1'] ).to be_empty
      expect( queue.processing_data shard_index ).to be_empty
    end

    it 'error' do
      expect($retry_in).to receive(:call).with(0).and_return(10)
      expect($perform).to receive(:call).at_least(:once).and_raise(StandardError.new "error")

      worker.perform_async(
        [
          { id: 1, payload: "v1", score: 0 },
          { id: 1, payload: "v2", score: 1 },
        ]
      )

      expect( shard.process ).to be(false)
      expect( queue.processing_data shard_index ).to be_empty

      expected_in_queue = {
        id: '1', retry_count: 0, perform_in: $now + 10, error: "error",
        payloads: [['v1', 0],
                   ['v2', 1]],
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected_in_queue)
      expect( queries.morgue_fetch ['1'] ).to be_empty
    end

    it 'morgue' do
      expect($retry_in).to receive(:call).with( worker.max_retry_count ).and_return(10)
      expect($perform).to receive(:call).at_least(:once).and_raise(StandardError.new "error")

      worker.perform_async(
        [
          { id: 1, payload: "v1", score: 0, retry_count: worker.max_retry_count - 1 },
          { id: 1, payload: "v2", score: 1, retry_count: worker.max_retry_count - 1 },
        ]
      )

      expect( shard.process ).to be(false)
      expect( queue.processing_data shard_index ).to be_empty

      expected_in_queue = {
        id: '1', retry_count: 0, perform_in: $now, error: "error",
        payloads: [['v2', 1]],
      }

      expect( queries.fetch ['1'] ).to contain_exactly(expected_in_queue)

      expected_in_morgue = {
        id: '1', payloads: [['v1', 0]], updated_at: $now, error: "error",
      }

      expect( queries.morgue_fetch ['1'] ).to contain_exactly(expected_in_morgue)
    end
  end

  it '#restore' do
    expect($perform).to receive(:call).and_raise(Exception.new "fatal error")

    worker.perform_async(
      [
        { id: 1, payload: "v1" },
      ]
    )

    expect{ shard.process }.to raise_error(Exception, "fatal error")
    expect( queue.processing_data shard_index ).to be_any

    shard.restore

    expect( queue.processing_data shard_index ).to be_empty

    expected = {
      id: '1', retry_count: -1, perform_in: $now,
      payloads: [ ['v1', $now] ],
    }
    expect( queries.fetch ['1'] ).to contain_exactly(expected)
  end
end
