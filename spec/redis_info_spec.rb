RSpec.describe Lowkiq::RedisInfo do
  let(:redis_pool) { ConnectionPool.new(size: 5, timeout: 5) { Redis.new url: ENV['REDIS_URL'] } }

  let(:subject) { described_class.new redis_pool }

  it "call" do
    expect( subject.call ).to be
  end
end
