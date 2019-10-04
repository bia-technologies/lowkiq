import React from 'react';

import Dashboard from '../dumb/dashboard';

export default function dashboardFactory(client) {
  return class DashboardManager extends React.Component {
    constructor(props) {
      super(props);
      this.state = {
        queues: [],
        redis_info: {}
      };
      this.period = 1000;
    }

    tick() {
      client
        .dashboard()
        .then(dashboard => this.setState(dashboard));
    }

    componentDidMount() {
      this.tick();
      this.interval = setInterval(() => this.tick(), this.period);
    }

    componentWillUnmount() {
      clearInterval(this.interval);
      // TODO: cancel request
    }

    render() {
      return <Dashboard {...this.state} />;
    }
  };
}
