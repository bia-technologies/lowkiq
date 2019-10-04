import React from 'react';

import Pulse from './pulse';
import Total from './total';
import Chart from './chart';
import Table from './table';
import RedisInfo from './redis-info';

export default function Dashboard({queues, redis_info}) {
  const total = {
    processed: queues.reduce( (sum, q) => sum + q.processed, 0 ),
    failed:    queues.reduce( (sum, q) => sum + q.failed, 0 ),
    lag:       queues.reduce( (acc, q) => Math.max(acc, q.lag), 0 ),
    busy:      queues.reduce( (sum, q) => sum + q.busy, 0 ),
    enqueued:  queues.reduce( (sum, q) => sum + q.enqueued, 0 ),
    fresh:     queues.reduce( (sum, q) => sum + q.fresh, 0 ),
    retries:   queues.reduce( (sum, q) => sum + q.retries, 0 ),
    dead:      queues.reduce( (sum, q) => sum + q.dead, 0 )
  };

  return (
    <div className="container">
      <div className="d-flex justify-content-between align-items-baseline">
        <h1 className="my-3">
          Lowkiq dashboard
        </h1>
        <Pulse />
      </div>
      <Total {...total} />
      <Chart {...total} />
      <Table queues={queues} />
      <RedisInfo {...redis_info} />
    </div>
  );
}
