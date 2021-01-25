require "rack/test"

RSpec.describe Lowkiq::Web do
  include Rack::Test::Methods

  module ApiTestWorker
    extend Lowkiq::Worker

    def self.perform(batch)
    end
  end

  def app
    described_class
  end

  def json_last_response
    JSON.parse(last_response.body)
  end

  around(:each) do |t|
    saved = Lowkiq.workers
    Lowkiq.workers = [ApiTestWorker]
    begin
      t.call
    ensure
      Lowkiq.workers = saved
    end
  end

  before(:each) { Lowkiq.server_redis_pool.with(&:flushdb)  }
  before(:each) { Lowkiq.server_redis_pool.with { |r| Lowkiq::Script.load! r } }
  before(:each) { ApiTestWorker.perform_async [ {id: 1, payload: "v1"} ] }

  it 'dashboard' do
    get '/api/web/dashboard'

    expect( last_response.status ).to eq(200)
  end

  context 'api' do
    it 'stats' do
      get '/api/v1/stats'

      expect( last_response.status ).to eq(200)
      expect( json_last_response['total']['length'] ).to be(1)
      expect( json_last_response['total']['morgue_length'] ).to be(0)
      expect( json_last_response['total']['lag'] ).to be_within(0.1).of(0.0)

      expect( json_last_response['by_worker']['ApiTestWorker']['length'] ).to be(1)
      expect( json_last_response['by_worker']['ApiTestWorker']['morgue_length'] ).to be(0)
      expect( json_last_response['by_worker']['ApiTestWorker']['lag'] ).to be_within(0.1).of(0.0)
    end
  end

  context 'web_api' do
    # %2B is `+`
    it 'range_by_id' do
      get "/api/web/ApiTestWorker/range_by_id", min: '-', max: '+'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(1)
    end

    it 'rev_range_by_id' do
      get "/api/web/ApiTestWorker/rev_range_by_id", max: '+', min: '-'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(1)
    end

    it 'range_by_perform_in' do
      get "/api/web/ApiTestWorker/range_by_perform_in", min: '-inf', max: '+inf'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(1)
    end

    it 'rev_range_by_perform_in' do
      get "/api/web/ApiTestWorker/rev_range_by_perform_in", max: '+inf', min: '-inf'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(1)
    end

    it 'range_by_retry_count' do
      get "/api/web/ApiTestWorker/range_by_retry_count", min: '-inf', max: '+inf'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(1)
    end

    it 'rev_range_by_retry_count' do
      get "/api/web/ApiTestWorker/rev_range_by_retry_count", max: '+inf', min: '-inf'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(1)
    end

    it 'processing_data' do
      get '/api/web/ApiTestWorker/processing_data'
      expect( last_response.status ).to eq(200)
      expect { json_last_response }.to_not raise_error
    end

    it 'morgue_range_by_id' do
      get "/api/web/ApiTestWorker/morgue_range_by_id", min: '-', max: '+'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(0)
    end

    it 'morgue_rev_range_by_id' do
      get "/api/web/ApiTestWorker/morgue_rev_range_by_id", max: '+', min: '-'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(0)
    end

    it 'morgue_range_by_updated_at' do
      get "/api/web/ApiTestWorker/morgue_range_by_updated_at?", min: '-inf', max: '+inf'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(0)
    end

    it 'morgue_rev_range_by_updated_at' do
      get "/api/web/ApiTestWorker/morgue_rev_range_by_updated_at", max: '+inf', min: '-inf'

      expect( last_response.status ).to eq(200)
      expect( json_last_response.length ).to be(0)
    end

    context "operations" do
      before(:each) do
        allow(Thread).to receive(:new) { |&block| block.call }
      end

      it 'morgue_queue_up' do
        post '/api/web/ApiTestWorker/morgue_queue_up', ids: [1,2,3]
        expect( last_response.status ).to eq(200)
        expect( json_last_response ).to eq('ok')
      end

      it 'morgue_delete' do
        post '/api/web/ApiTestWorker/morgue_delete', ids: [1,2,3]
        expect( last_response.status ).to eq(200)
        expect( json_last_response ).to eq('ok')
      end

      it 'morgue_queue_up_all' do
        post '/api/web/ApiTestWorker/morgue_queue_up_all_jobs'
        expect( last_response.status ).to eq(200)
        expect( json_last_response ).to eq('ok')
      end

      it 'morgue_delete_all_jobs' do
        post '/api/web/ApiTestWorker/morgue_delete_all_jobs'
        expect( last_response.status ).to eq(200)
        expect( json_last_response ).to eq('ok')
      end

      it 'perform_all_jobs_now' do
        post '/api/web/ApiTestWorker/perform_all_jobs_now'
        expect( last_response.status ).to eq(200)
        expect( json_last_response ).to eq('ok')
      end

      it 'kill_all_failed_jobs' do
        post '/api/web/ApiTestWorker/kill_all_failed_jobs'
        expect( last_response.status ).to eq(200)
        expect( json_last_response ).to eq('ok')
      end

      it 'delete_all_failed_jobs' do
        post '/api/web/ApiTestWorker/delete_all_failed_jobs'
        expect( last_response.status ).to eq(200)
        expect( json_last_response ).to eq('ok')
      end
    end
  end
end
