[![Gem Version](https://badge.fury.io/rb/lowkiq.svg)](https://badge.fury.io/rb/lowkiq)

# Lowkiq

Ordered background jobs processing

![dashboard](doc/dashboard.png)

* [Rationale](#rationale)
* [Description](#description)
* [Sidekiq comparison](#sidekiq-comparison)
* [Queue](#queue)
  + [Calculation algorithm for `retry_count` and `perform_in`](#calculation-algorithm-for-retry_count-and-perform_in)
  + [Job merging rules](#job-merging-rules)
* [Install](#install)
* [Api](#api)
* [Ring app](#ring-app)
* [Configuration](#configuration)
* [Performance](#performance)
* [Execution](#execution)
* [Shutdown](#shutdown)
* [Debug](#debug)
* [Development](#development)
* [Exceptions](#exceptions)
* [Rails integration](#rails-integration)
* [Splitter](#splitter)
* [Scheduler](#scheduler)
* [Recommendations on configuration](#recommendations-on-configuration)
  + [`SomeWorker.shards_count`](#someworkershards_count)
  + [`SomeWorker.max_retry_count`](#someworkermax_retry_count)

## Rationale

We've faced some problems using Sidekiq while processing messages from a side system.
For instance, the message is a data of an order in particular time.
The side system will send a new data of an order on an every change.
Orders are frequently updated and a queue containts some closely located messages of the same order.

Sidekiq doesn't guarantee a strict message order, because a queue is processed by multiple threads.
For example, we've received 2 messages: M1 and M2.
Sidekiq handlers begin to process them parallel,
so M2 can be processed before M1.

Parallel processing of such kind of messages can result in:

+ dead locks
+ overwriting new data with old one

Lowkiq has been created to eliminate such problems by avoiding parallel task processing within one entity.

## Description

Lowkiq's queues are reliable i.e.,
Lowkiq saves information about a job being processed
and returns incompleted jobs back to the queue on startup.

Jobs in queues are ordered by preassigned execution time, so they are not FIFO queues.

Every job has it's own identifier. Lowkiq guarantees that jobs with equal id are processed by the same thread.

Every queue is divided into a permanent set of shards.
A job is placed into particular shard based on an id of the job.
So jobs with the same id are always placed into the same shard.
All jobs of the shard are always processed with the same thread.
This guarantees the sequently processing of jobs with the same ids and excludes the possibility of locks.

Besides the id, every job has a payload.
Payloads are accumulated for jobs with the same id.
So all accumulated payloads will be processed together.
It's useful when you need to process only the last message and drop all previous ones.

A worker corresponds to a queue and contains a job processing logic.

Fixed amount of threads is used to process all job of all queues.
Adding or removing queues or it's shards won't affect the amount of threads.

## Sidekiq comparison

If Sidekiq is good for your tasks you should use it.
But if you use plugins like
[sidekiq-grouping](https://github.com/gzigzigzeo/sidekiq-grouping),
[sidekiq-unique-jobs](https://github.com/mhenrixon/sidekiq-unique-jobs),
[sidekiq-merger](https://github.com/dtaniwaki/sidekiq-merger)
or implement your own lock system, you should look at Lowkiq.

For example, sidekiq-grouping accumulates a batch of jobs than enqueues it and accumulates a next batch.
With this approach queue can contains two batches with a data of the same order.
These batches are parallel processed with different threads, so we come back to the initial problem.

Lowkiq was designed to avoid any types of locking.

Furthermore, Lowkiq's queues are reliable. Only Sidekiq Pro or plugins can add such functionality.

This [benchmark](examples/benchmark) shows overhead on redis usage.
This is the results for 5 threads, 100,000 blank jobs:

+ lowkiq: 155 sec or 1.55 ms per job
+ lowkiq +hiredis: 80 sec or 0.80 ms per job
+ sidekiq: 15 sec or 0.15 ms per job

This difference is related to different queues structure.
Sidekiq uses one list for all workers and fetches the job entirely for O(1).
Lowkiq uses several data structures, including sorted sets for storing ids of jobs.
So fetching only an id of a job takes O(log(N)).

## Queue

Please, look at [the presentation](https://docs.google.com/presentation/d/e/2PACX-1vRdwA2Ck22r26KV1DbY__XcYpj2FdlnR-2G05w1YULErnJLB_JL1itYbBC6_JbLSPOHwJ0nwvnIHH2A/pub?start=false&loop=false&delayms=3000).

Every job has following attributes:

+ `id` is a job identifier with string type.
+ `payloads` is a sorted set of payloads ordered by it's score. Payload is an object. Score is a real number.
+ `perform_in` is planned execution time. It's unix timestamp with real number type.
+ `retry_count` is amount of retries. It's a real number.

For example, `id` can be an identifier of replicated entity.
`payloads` is a sorted set ordered by score of payload and resulted by grouping a payload of job by it's `id`.
`payload` can be a ruby object, because it is serialized by `Marshal.dump`.
`score` can be `payload`'s creation date (unix timestamp) or it's incremental version number.
By default `score` and `perform_in` are current unix timestamp.
`retry_count` for new unprocessed job equals to `-1`,
for one-time failed is `0`, so the planned retries are counted, not the performed ones.

A job execution can be unsuccessful. In this case, its `retry_count` is incremented, new `perform_in` is calculated with determined formula and it moves back to a queue.

In case of `retry_count` is getting `>=` `max_retry_count` an element of `payloads` with less (oldest) score is moved to a morgue,
rest elements are moved back to the queue, wherein `retry_count` and `perform_in` are reset to `-1` and `now()` respectively.

### Calculation algorithm for `retry_count` and `perform_in`

0. a job's been executed and failed
1. `retry_count++`
2. `perform_in = now + retry_in (try_count)`
3. `if retry_count >= max_retry_count` the job will be moved to a morgue.

| type                      | `retry_count` | `perform_in`          |
| ---                       | ---           | ---                   |
| new haven't been executed | -1            | set or `now()`        |
| new failed                | 0             | `now() + retry_in(0)` |
| retry failed              | 1             | `now() + retry_in(1)` |

If `max_retry_count = 1`, retries stop.

### Job merging rules

They are applied when:

+ a job had been in a queue and a new one with the same id was added
+ a job was failed, but a new one with the same id had been added
+ a job from morgue was moved back to queue, but queue had had a job with the same id

Algorithm:

+ payloads is merged, minimal score is chosen for equal payloads
+ if a new job and queued job is merged, `perform_in` and `retry_count` is taken from the the job from the queue
+ if a failed job and queued job is merged, `perform_in` and `retry_count` is taken from the failed one
+ if morgue job and queued job is merged, `perform_in = now()`, `retry_count = -1`

Example:

```
# v1 is the first version and v2 is the second
# #{"v1": 1} is a sorted set of a single element, the payload is "v1", the score is 1

# a job is in a queue
{ id: "1", payloads: #{"v1": 1, "v2": 2}, retry_count: 0, perform_in: 1536323288 }
# a job which is being added
{ id: "1", payloads: #{"v2": 3, "v3": 4}, retry_count: -1, perform_in: 1536323290 }

# a resulted job in the queue
{ id: "1", payloads: #{"v1": 1, "v2": 3, "v3": 4}, retry_count: 0, perform_in: 1536323288 }
```

Morgue is a part of the queue. Jobs in morgue are not processed.
A job in morgue has following attributes:

+ id is the job identifier
+ payloads

A job from morgue can be moved back to the queue, `retry_count` = 0 and `perform_in = now()` would be set.

## Install

```
# Gemfile

gem 'lowkiq'
```

Redis >= 3.2

## Api

```ruby
module ATestWorker
  extend Lowkiq::Worker

  self.shards_count = 24
  self.batch_size = 10
  self.max_retry_count = 5

  def self.retry_in(count)
    10 * (count + 1) # (i.e. 10, 20, 30, 40, 50)
  end

  def self.perform(payloads_by_id)
    # payloads_by_id is a hash map
    payloads_by_id.each do |id, payloads|
      # payloads are sorted by score, from old to new (min to max)
      payloads.each do |payload|
        do_some_work(id, payload)
      end
    end
  end
end
```

Default values:

```ruby
self.shards_count = 5
self.batch_size = 1
self.max_retry_count = 25
self.queue_name = self.name

# i.e. 15, 16, 31, 96, 271, ... seconds + a random amount of time
def retry_in(retry_count)
  (retry_count ** 4) + 15 + (rand(30) * (retry_count + 1))
end
```

```ruby
ATestWorker.perform_async [
  { id: 0 },
  { id: 1, payload: { attr: 'v1' } },
  { id: 2, payload: { attr: 'v1' }, score: Time.now.to_i, perform_in: Time.now.to_i },
]
# payload by default equals to ""
# score and perform_in by default equals to Time.now.to_i
```

It is possible to redefine `perform_async` and calculate `id`, `score` и `perform_in` in a worker code:

```ruby
module ATestWorker
  extend Lowkiq::Worker

  def self.perform_async(jobs)
    jobs.each do |job|
      job.merge! id: job[:payload][:id]
    end
    super
  end

  def self.perform(payloads_by_id)
    #...
  end
end

ATestWorker.perform_async 1000.times.map { |id| { payload: {id: id} } }
```

## Ring app

`Lowkiq::Web` - a ring app.

+ `/` - a dashboard
+ `/api/v1/stats` - queue length, morgue length, lag for each worker and total result

## Configuration

Default options and values are:

+ `Lowkiq.poll_interval = 1` - delay in seconds between queue polling for new jobs.
   Used only if the queue was empty at previous cycle or error was occured.
+ `Lowkiq.threads_per_node = 5` - threads per node.
+ `Lowkiq.redis = ->() { Redis.new url: ENV.fetch('REDIS_URL') }` - redis connection options
+ `Lowkiq.client_pool_size = 5` - redis pool size for queueing jobs
+ `Lowkiq.pool_timeout = 5` - client and server redis pool timeout
+ `Lowkiq.server_middlewares = []` - a middleware list, used for worker wrapping
+ `Lowkiq.on_server_init = ->() {}` - a lambda is being executed when server inits
+ `Lowkiq.build_scheduler = ->() { Lowkiq.build_lag_scheduler }` is a scheduler
+ `Lowkiq.build_splitter = ->() { Lowkiq.build_default_splitter }` is a splitter
+ `Lowkiq.last_words = ->(ex) {}` is an exception handler of descendants of `StandardError` caused the process stop

```ruby
$logger = Logger.new(STDOUT)

Lowkiq.server_middlewares << -> (worker, batch, &block) do
  $logger.info "Started job for #{worker} #{batch}"
  block.call
  $logger.info "Finished job for #{worker} #{batch}"
end

Lowkiq.server_middlewares << -> (worker, batch, &block) do
  begin
    block.call
  rescue => e
    $logger.error "#{e.message} #{worker} #{batch}"
    raise e
  end
end
```

## Performance

Use [hiredis](https://github.com/redis/hiredis-rb) for better performance.

```ruby
# Gemfile

gem "hiredis"
```

```ruby
# config

Lowkiq.redis = ->() { Redis.new url: ENV.fetch('REDIS_URL'), driver: :hiredis }
```

## Execution

`lowkiq -r ./path_to_app`

`path_to_app.rb` must load app. [Example](examples/dummy/lib/app.rb).

Lazy loading of workers modules is unacceptable.
For preliminarily loading modules use
`require`
or [`require_dependency`](https://api.rubyonrails.org/classes/ActiveSupport/Dependencies/Loadable.html#method-i-require_dependency)
for Ruby on Rails.

## Shutdown

Send TERM or INT signal to process (Ctrl-C).
Process will wait for executed jobs to finish.

Note that if queue is empty, process sleeps `poll_interval` seconds,
therefore, the process will not stop until the `poll_interval` seconds have passed.

## Debug

To get trace of all threads of app:

```
kill -TTIN <pid>
cat /tmp/lowkiq_ttin.txt
```

## Development

```
docker-compose run --rm --service-port app bash
bundle
rspec
cd examples/dummy ; bundle exec ../../exe/lowkiq -r ./lib/app.rb
```

## Exceptions

`StandardError` thrown by worker are handled with middleware. Such exceptions doesn't lead to process stop.

All other exceptions cause the process to stop.
Lowkiq will wait for job execution by other threads.

`StandardError` thrown outside of worker are passed to `Lowkiq.last_words`.
For example, it can happen when Redis connection is lost or when Lowkiq's code has a bug.

## Rails integration

```ruby
# config/routes.rb

Rails.application.routes.draw do
 # ...
 mount Lowkiq::Web => '/lowkiq'
 # ...
end
```

```ruby
# config/initializers/lowkiq.rb

# loading all lowkiq workers
Dir["#{Rails.root}/app/lowkiq_workers/**/*.rb"].each { |file| require_dependency file }

# configuration:
# Lowkiq.redis = -> { Redis.new url: ENV.fetch('LOWKIQ_REDIS_URL') }
# Lowkiq.threads_per_node = ENV.fetch('LOWKIQ_THREADS_PER_NODE').to_i
# Lowkiq.client_pool_size = ENV.fetch('LOWKIQ_CLIENT_POOL_SIZE').to_i
# ...

Lowkiq.server_middlewares << -> (worker, batch, &block) do
  logger = Rails.logger
  tag = "#{worker}-#{Thread.current.object_id}"

  logger.tagged(tag) do
    time_start = Time.now
    logger.info "#{time_start} Started job, batch: #{batch}"
    begin
      block.call
    rescue => e
      logger.error e.message
      raise e
    ensure
      time_end = Time.now
      logger.info "#{time_end} Finished job, duration: #{time_end - time_start} sec"
    end
  end
end

# Sentry integration
Lowkiq.server_middlewares << -> (worker, batch, &block) do
  opts = {
    extra: {
      lowkiq: {
        worker: worker.name,
        batch: batch,
      }
    }
  }

  Raven.capture opts do
    block.call
  end
end

# NewRelic integration
if defined? NewRelic
  class NewRelicLowkiqMiddleware
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def call(worker, batch, &block)
      opts = {
        category: 'OtherTransaction/LowkiqJob',
        class_name: worker.name,
        name: :perform,
      }

      perform_action_with_newrelic_trace opts do
        block.call
      end
    end
  end

  Lowkiq.server_middlewares << NewRelicLowkiqMiddleware.new
end

# Rails reloader, responsible for cleaning of ActiveRecord connections
Lowkiq.server_middlewares << -> (worker, batch, &block) do
  Rails.application.reloader.wrap do
    block.call
  end
end

Lowkiq.on_server_init = ->() do
  [[ActiveRecord::Base, ActiveRecord::Base.configurations[Rails.env]]].each do |(klass, init_config)|
    klass.connection_pool.disconnect!
    config = init_config.merge 'pool' => Lowkiq.threads_per_node
    klass.establish_connection(config)
  end
end
```

Execution: `bundle exec lowkiq -r ./config/environment.rb`


## Splitter

Each worker has several shards:

```
# worker: shard ids
worker A: 0, 1, 2
worker B: 0, 1, 2, 3
worker C: 0
worker D: 0, 1
```

Lowkiq uses fixed amount of threads for job processing, therefore it is necessary to distribute shards between threads.
Splitter does it.

To define a set of shards, which is being processed by thread, lets move them to one list:

```
A0, A1, A2, B0, B1, B2, B3, C0, D0, D1
```

Default splitter evenly distributes shards by threads of a single node.

If `threads_per_node` is set to 3, the distribution will be:

```
# thread id: shards
t0: A0, B0, B3, D1
t1: A1, B1, C0
t2: A2, B2, D0
```

Besides Default Lowkiq has ByNode splitter. It allows to divide the load by several processes (nodes).

```
Lowkiq.build_splitter = -> () do
  Lowkiq.build_by_node_splitter(
    ENV.fetch('LOWKIQ_NUMBER_OF_NODES').to_i,
    ENV.fetch('LOWKIQ_NODE_NUMBER').to_i
  )
end
```

So, instead of single process you need to execute multiple ones and to set environment variables up:

```
# process 0
LOWKIQ_NUMBER_OF_NODES=2 LOWKIQ_NODE_NUMBER=0 bundle exec lowkiq -r ./lib/app.rb

# process 1
LOWKIQ_NUMBER_OF_NODES=2 LOWKIQ_NODE_NUMBER=1 bundle exec lowkiq -r ./lib/app.rb
```

Summary amount of threads are equal product of `ENV.fetch('LOWKIQ_NUMBER_OF_NODES')` and `Lowkiq.threads_per_node`.

You can also write your own splitter if your app needs extra distribution of shards between threads or nodes.

## Scheduler

Every thread processes a set of shards. Scheduler select shard for processing.
Every thread has it's own instance of scheduler.

Lowkiq has 2 schedulers for your choice.
`Seq` sequentally looks over shards.
`Lag`  chooses shard with the oldest job minimizing the lag. It's used by default.

Scheduler can be set up through settings:

```
Lowkiq.build_scheduler = ->() { Lowkiq.build_seq_scheduler }
# or
Lowkiq.build_scheduler = ->() { Lowkiq.build_lag_scheduler }
```

## Recommendations on configuration

### `SomeWorker.shards_count`

Sum of `shards_count` of all workers shouldn't be less than `Lowkiq.threads_per_node`
otherwise threads will stay idle.

Sum of `shards_count` of all workers can be equal to `Lowkiq.threads_per_node`.
In this case thread processes a single shard. This makes sense only with uniform queue load.

Sum of `shards_count` of all workers can be more than `Lowkiq.threads_per_node`.
In this case `shards_count` can be counted as a priority.
The larger it is, the more often the tasks of this queue will be processed.

There is no reason to set `shards_count` of one worker more than `Lowkiq.threads_per_node`,
because every thread will handle more than one shard from this queue, so it increases the overhead.

### `SomeWorker.max_retry_count`

From `retry_in` and `max_retry_count`, you can calculate approximate time that payload of job will be in a queue.
After `max_retry_count` is reached the payload with a minimal score will be moved to a morgue.

For default `retry_in` we receive the following table.

```ruby
def retry_in(retry_count)
  (retry_count ** 4) + 15 + (rand(30) * (retry_count + 1))
end
```

| `max_retry_count` | amount of days of job's life |
| ---               | ---                          |
| 14                | 1                            |
| 16                | 2                            |
| 18                | 3                            |
| 19                | 5                            |
| 20                | 6                            |
| 21                | 8                            |
| 22                | 10                           |
| 23                | 13                           |
| 24                | 16                           |
| 25                | 20                           |

`(0...25).map{ |c| retry_in c }.sum / 60 / 60 / 24`


## Changing of worker's shards amount

Try to count amount of shards right away and don't change it in future.

If you can disable adding of new jobs, wait for queues to get empty and deploy the new version of code with changed amount of shards.

If you can't do it, follow the next steps:

A worker example:

```ruby
module ATestWorker
  extend Lowkiq::Worker

  self.shards_count = 5

  def self.perform(payloads_by_id)
    some_code
  end
end
```

Set the number of shards and new queue name:

```ruby
module ATestWorker
  extend Lowkiq::Worker

  self.shards_count = 10
  self.queue_name = "#{self.name}_V2"

  def self.perform(payloads_by_id)
    some_code
  end
end
```

Add a worker moving jobs from the old queue to a new one:

```ruby
module ATestMigrationWorker
  extend Lowkiq::Worker

  self.shards_count = 5
  self.queue_name = "ATestWorker"

  def self.perform(payloads_by_id)
    jobs = payloads_by_id.each_with_object([]) do |(id, payloads), acc|
      payloads.each do |payload|
        acc << { id: id, payload: payload }
      end
    end

    ATestWorker.perform_async jobs
  end
end
```
