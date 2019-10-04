RSpec.describe Lowkiq::Schedulers::Lag do
  let(:shard_handler) { double("shard_handler") }
  let(:metrics) { double("metrics") }
  let(:wait) { double("wait") }

  subject { described_class.new wait, metrics }

  it 'process' do
    expect(metrics).to receive(:call).and_return([OpenStruct.new(lag: 1)])
    expect(shard_handler).to receive(:queue_name).and_return("name")
    expect(shard_handler).to receive(:shard_index).and_return(0)
    expect(shard_handler).to receive(:process).and_return(true)
    job = subject.build_job [shard_handler]
    job.call
  end

  it 'wait' do
    expect(metrics).to receive(:call).and_return([OpenStruct.new(lag: 0)])
    expect(wait).to receive(:call).exactly(1)
    expect(shard_handler).to receive(:queue_name).and_return("name")
    expect(shard_handler).to receive(:shard_index).and_return(0)

    job = subject.build_job [shard_handler]
    job.call
  end
end
