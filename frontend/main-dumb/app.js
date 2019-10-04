import React from 'react';
import _get from 'lodash/get';

import App from '../src/dumb/app';
import Dashboard from '../src/dumb/dashboard';
import Busy from '../src/dumb/details/busy';
import Enqueued from '../src/dumb/details/enqueued';
import Dead from '../src/dumb/details/dead';

function rnd(max) {
  return Math.floor( Math.random() * max );
}

class DashboardManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      queues: [
        {
          name: "AwesomeProject::CoolModule::SomeWorker",
          lag: 3010,
          processed: 10000,
          failed: 100000,
          busy: 1883,
          enqueued: 8329,
          fresh: 79998,
          retries: 7968,
          dead: 979878987
        }
      ]
    };
  }

  tick() {
    this.setState(state => ({
      queues: state.queues.map( q => {
        const c = Object.assign({}, q);
        c.processed += rnd(10);
        c.failed += rnd(2);
        return c;
      })
    }));
  }

  componentDidMount() {
    this.interval = setInterval(() => this.tick(), 1000);
  }

  componentWillUnmount() {
    clearInterval(this.interval);
  }

  redisInfo() {
    return {
      url: "redis://asfdasfd-asdfasdf-asdf",
      version: "4.4.4",
      uptime_in_days: 10,
      connected_clients: 100,
      used_memory_human: "100M",
      used_memory_peak_human: "500M"
    };
  }

  render() {
    return <Dashboard queues={this.state.queues} redis_info={this.redisInfo()}/>;
  }
}

function BusyManager(params) {
  const queue = params.match.params.name;
    const items = [
    {
      id: "1918f2e4-d5ee-4ffd-bbd6-6faf4020c97d",
      perform_in: 1541763528,
      retry_count: -1,
      error: "some error",
      payloads: [
        ["foo bar",  1541763533],
        ["foo buzz", 1541763534],
      ]
    }
  ];
  return <Busy name={queue} items={items} order={{id: "desc"}} />;
}

function EnqueuedManager(params) {
  const selectedFilter = _get(
    params,
    'location.state.selectedFilter',
    {id: {min: '-inf', max: '+inf', rev: false}}
  );

  const queue = params.match.params.name;
  const items = [
    {
      id: "1918f2e4-d5ee-4ffd-bbd6-6faf4020c97d",
      perform_in: 1541763528,
      retry_count: 10,
      error: "some error",
      payloads: [
        ["foo bar",  1541763533],
        ["foo buzz", 1541763534],
      ]
    }
  ];
  return (
    <Enqueued
      name={queue}
      items={items}
      onPerformAllJobsNow={() => console.log('perfrom all jobs now')}
      onKillAllFailedJobs={() => console.log('kill all failed jobs')}
      onDeleteAllFailedJobs={() => console.log('delete all failed jobs')}
      selectedFilter={selectedFilter}
      onFilter={(...args) => console.log(args)} />
  );
}

function DeadManager(params) {
  const queue = params.match.params.name;
  const items = [
    {
      id: "1918f2e4-d5ee-4ffd-bbd6-6faf4020c97d",
      updated_at: 1541763528,
      payloads: [
        ["foo bar", 1541763528],
        ["Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce consequat augue orci, in luctus libero lacinia sit amet.", 1541763534],
      ],
      error: "some error",
      actions: {
        onQueueUp: () => console.log("queue up"),
        onDelete:  () => console.log("delete")
      }
    },
    {
      id: "1918f2e4-d5ee-4ffd-bbd6-6faf4020c978",
      updated_at: 1541763528,
      payloads: [
        ["foo bar", 1541763528],
        ["Lorem ipsum dolor sit amet, consectetur adipiscing elit.", 1541763534],
      ],
      error: "some error",
      actions: {
        onQueueUp: () => console.log("queue up"),
        onDelete:  () => console.log("delete")
      }
    }
  ];
  return (
    <Dead name={queue}
          items={items}
          selectedFilter={{id: {min: '-inf', max: '+inf', rev: false}}}
          onFilter={(...args) => console.log(args)}
      onQueueUpAllJobs={() => console.log('queue up all jobs')}
      onDeleteAllJobs={() => console.log('delete all jobs')} />
  );
}

export default function Main() {
  return (
    <App rootUrl=""
         Dashboard={DashboardManager}
         Busy={BusyManager}
         Enqueued={EnqueuedManager}
         Dead={DeadManager}
         />
  );
};
