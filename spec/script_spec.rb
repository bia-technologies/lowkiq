RSpec.describe Lowkiq::Script do
  let(:redis_pool) { ConnectionPool.new(size: 5, timeout: 5) { Redis.new url: ENV['REDIS_URL'] } }

  before(:each) { redis_pool.with(&:flushdb) }
  before(:each) { redis_pool.with { |r| described_class.load! r } }

  describe 'hmove' do
    let(:source) { "source" }
    let(:destination) { "destination" }

    let(:key) { "my-key" }
    let(:value) { "my-value" }

    it 'ok' do
      redis_pool.with do |redis|
        redis.hset "source", key, value
        described_class.hmove redis, source, destination, key

        expect(redis.hexists source, key).to eq(false)
        expect(redis.hget destination, key).to eq(value)
      end
    end

    it 'with missed member' do
      redis_pool.with do |redis|
        described_class.hmove redis, source, destination, key

        expect(redis.hexists source, key).to eq(false)
        expect(redis.hget destination, key).to eq(nil)
      end
    end
  end

  describe 'zremhset' do
    let(:source) { "source" }
    let(:destination) { "destination" }

    let(:score) { 10 }
    let(:member) { "some member" }

    it 'ok' do
      redis_pool.with do |redis|
        redis.zadd "source", score, member
        described_class.zremhset redis, source, destination, member

        expect(redis.zscore source, member).to eq(nil)
        expect(redis.hgetall destination).to eq({member => score.to_s})
      end
    end

    it 'with missed member' do
      redis_pool.with do |redis|
        described_class.zremhset redis, source, destination, member

        expect(redis.zscore source, member).to eq(nil)
        expect(redis.hgetall destination).to eq({})
      end
    end
  end
end
