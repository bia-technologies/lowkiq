import './bootstrap.scss';

import 'whatwg-fetch';

import React from 'react';
import { BrowserRouter as Router, Route, Link } from "react-router-dom";

import {Routes, RoutesContext} from './routes';

export default function App({rootUrl, Dashboard, Busy, Enqueued, Dead}) {
  const routes = new Routes(rootUrl);

  return (
    <RoutesContext.Provider value={routes}>
      <Router>
        <div>
          <Route path={routes.dashboard()} exact component={Dashboard} />
          <Route path={routes.busy(':name')} component={Busy} />
          <Route path={routes.enqueued(':name')} component={Enqueued} />
          <Route path={routes.dead(':name')} component={Dead} />
        </div>
      </Router>
    </RoutesContext.Provider>
  );
}
