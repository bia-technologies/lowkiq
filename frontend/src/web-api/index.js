import React from 'react';

import App from '../dumb/app';

import Client from './client';

import dashboardFactory from './dashboard';
import EnqueuedFactory from './details/enqueued';
import DeadFactory from './details/dead';
import BusyFactory from './details/busy';

export default function factory(baseApiUrl, rootUrl) {
  const client = new Client(baseApiUrl);

  const Dashboard = dashboardFactory(client);

  const Enqueued = EnqueuedFactory(client);
  const Dead = DeadFactory(client);
  const Busy = BusyFactory(client);

  return function Main() {
    return (
      <App rootUrl={rootUrl}
           Dashboard={Dashboard}
           Busy={Busy}
           Enqueued={Enqueued}
           Dead={Dead}
           />
    );
  };
};
