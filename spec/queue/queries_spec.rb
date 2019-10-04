RSpec.describe Lowkiq::Queue::Queries do

  let(:redis_pool) { ConnectionPool.new(size: 5, timeout: 5) { Redis.new url: ENV['REDIS_URL'] } }
  let(:shards_count) { 1 }
  let(:shard_index) { 0 }

  let(:queue_name) { 'Test' }
  let(:queue) { Lowkiq::Queue::Queue.new redis_pool, queue_name, shards_count }
  let(:queries) { Lowkiq::Queue::Queries.new redis_pool, queue_name }

  before(:each) { redis_pool.with(&:flushdb) }
  before(:each) { $now = Lowkiq::Utils::Timestamp.now }
  before(:each) do
    allow(Lowkiq::Utils::Timestamp).to receive(:now) { $now }
  end

  describe 'queries' do
    describe 'empty' do
      it '#range_by_id' do
        expect( queries.range_by_id '-', '+' ).to be_empty
      end

      it '#rev_range_by_id' do
        expect( queries.rev_range_by_id '+', '-' ).to be_empty
      end

      it '#range_by_perfom_in' do
        expect( queries.range_by_perform_in '-inf', '+inf' ).to be_empty
      end

      it '#rev_range_by_perfom_in' do
        expect( queries.rev_range_by_perform_in '+inf', '-inf' ).to be_empty
      end

      it '#range_by_retry_count' do
        expect( queries.range_by_retry_count '-inf', '+inf' ).to be_empty
      end

      it '#rev_range_by_retry_count' do
        expect( queries.rev_range_by_retry_count '+inf', '-inf' ).to be_empty
      end

      it '#fetch' do
        expect( queries.fetch ['1', '2', '3'] ).to be_empty
      end

      it '#morgue_range_by_id' do
        expect( queries.morgue_range_by_id '-', '+' ).to be_empty
      end

      it '#morgue_rev_range_by_id' do
        expect( queries.morgue_rev_range_by_id '+', '-' ).to be_empty
      end

      it '#morgue_range_by_updated_at' do
        expect( queries.morgue_range_by_updated_at '-inf', '+inf' ).to be_empty
      end

      it '#morgue_rev_range_by_updated_at' do
        expect( queries.morgue_rev_range_by_updated_at '+inf', '-inf' ).to be_empty
      end

      it '#morgue_fetch' do
        expect( queries.morgue_fetch ['1', '2', '3'] ).to be_empty
      end
    end

    describe 'filled' do
      before(:each) do
        queue.push(
          [
            { id: '1', retry_count: 0,  perform_in: $now + 120, payload: "v1", score: $now },
            { id: '2', retry_count: -1, perform_in: $now + 60,  payload: "v1", score: $now },
          ]
        )
      end

      it '#fetch' do
        expected =
          [
            { id: '1', retry_count: 0,  perform_in: $now + 120, payloads: [['v1', $now]] },
            { id: '2', retry_count: -1, perform_in: $now + 60,  payloads: [['v1', $now]] },
          ]

        expect( queries.fetch ['1', '2'] ).to eq(expected)
      end

      it '#range_by_id' do
        expected =
          [
            { id: '1', retry_count: 0,  perform_in: $now + 120, payloads: [['v1', $now]] },
            { id: '2', retry_count: -1, perform_in: $now + 60,  payloads: [['v1', $now]] },
          ]

        expect( queries.range_by_id '-', '+' ).to eq(expected)
      end

      it '#rev_range_by_id' do
        expected =
          [
            { id: '2', retry_count: -1, perform_in: $now + 60,  payloads: [['v1', $now]] },
            { id: '1', retry_count: 0,  perform_in: $now + 120, payloads: [['v1', $now]] },
          ]

        expect( queries.rev_range_by_id '+', '-' ).to eq(expected)
      end

      it '#range_by_perform_in' do
        expected =
          [
            { id: '2', retry_count: -1, perform_in: $now + 60,  payloads: [['v1', $now]] },
            { id: '1', retry_count: 0,  perform_in: $now + 120, payloads: [['v1', $now]] },
          ]

        expect( queries.range_by_perform_in '-inf', '+inf' ).to eq(expected)
      end

      it '#rev_range_by_perform_in' do
        expected =
          [
            { id: '1', retry_count: 0,  perform_in: $now + 120, payloads: [['v1', $now]] },
            { id: '2', retry_count: -1, perform_in: $now + 60,  payloads: [['v1', $now]] },
          ]

        expect( queries.rev_range_by_perform_in '+inf', '-inf' ).to eq(expected)
      end

      it '#range_by_retry_count' do
        expected =
          [
            { id: '2', retry_count: -1, perform_in: $now + 60,  payloads: [['v1', $now]] },
            { id: '1', retry_count: 0,  perform_in: $now + 120, payloads: [['v1', $now]] },
          ]

        expect( queries.range_by_retry_count '-inf', '+inf' ).to eq(expected)
      end

      it '#rev_range_by_retry_count' do
        expected =
          [
            { id: '1', retry_count: 0,  perform_in: $now + 120, payloads: [['v1', $now]] },
            { id: '2', retry_count: -1, perform_in: $now + 60,  payloads: [['v1', $now]] },
          ]

        expect( queries.rev_range_by_retry_count '+inf', '-inf' ).to eq(expected)
      end
    end

    describe 'filled_morgue' do
      before(:each) do
        queue.push_to_morgue(
          [
            { id: '1', payloads: [['v1', $now]] },
            { id: '2', payloads: [['v1', $now]] },
          ]
        )
        $now += 1
        queue.push_to_morgue(
          [
            { id: '1', payloads: [['v1', $now]] },
          ]
        )
      end

      it '#morgue_fetch' do
        expected =
          [
            { id: '1', updated_at: $now,     payloads: [['v1', $now - 1]] },
            { id: '2', updated_at: $now - 1, payloads: [['v1', $now - 1]] },
          ]

        expect( queries.morgue_fetch ['1', '2'] ).to eq(expected)
      end

      it '#morgue_range_by_id' do
        expected =
          [
            { id: '1', updated_at: $now,     payloads: [['v1', $now - 1]] },
            { id: '2', updated_at: $now - 1, payloads: [['v1', $now - 1]] },
          ]

        expect( queries.morgue_range_by_id '-', '+' ).to eq(expected)
      end

      it '#morgue_rev_range_by_id' do
        expected =
          [
            { id: '2', updated_at: $now - 1, payloads: [['v1', $now - 1]] },
            { id: '1', updated_at: $now,     payloads: [['v1', $now - 1]] },
          ]

        expect( queries.morgue_rev_range_by_id '+', '-' ).to eq(expected)
      end

      it '#morgue_range_by_updated_at' do
        expected =
          [
            { id: '2', updated_at: $now - 1, payloads: [['v1', $now - 1]] },
            { id: '1', updated_at: $now,     payloads: [['v1', $now - 1]] },
          ]

        expect( queries.morgue_range_by_updated_at '-inf', '+inf' ).to eq(expected)
      end

      it '#morgue_rev_range_by_updated_at' do
        expected =
          [
            { id: '1', updated_at: $now,     payloads: [['v1', $now - 1]] },
            { id: '2', updated_at: $now - 1, payloads: [['v1', $now - 1]] },
          ]

        expect( queries.morgue_rev_range_by_updated_at '+inf', '-inf' ).to eq(expected)
      end
    end
  end
end
