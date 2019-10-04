RSpec.describe Lowkiq::Schedulers::Seq do
  let(:shard_handler_0) { double("shard_handler_0") }
  let(:shard_handler_1) { double("shard_handler_1") }
  let(:shard_handler_2) { double("shard_handler_2") }

  let(:shard_handlers) { [shard_handler_0, shard_handler_1, shard_handler_2] }

  let(:wait) { double("wait") }
  let(:threads_count) { 1 }

  let(:subject) { described_class.new wait }
  let(:job) { subject.build_job shard_handlers }

  it 'process' do
    2.times do
      expect(shard_handler_0).to receive(:process).and_return(false)
      job.call

      expect(shard_handler_1).to receive(:process).and_return(true)
      job.call

      expect(shard_handler_2).to receive(:process).and_return(true)
      job.call
    end
  end

  it 'wait' do
    expect(shard_handler_0).to receive(:process).and_return(false)
    job.call

    expect(shard_handler_1).to receive(:process).and_return(false)
    job.call

    expect(shard_handler_2).to receive(:process).and_return(false)
    job.call

    expect(wait).to receive(:call)
    job.call
  end
end
