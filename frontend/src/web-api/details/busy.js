import React from 'react';

import Busy from '../../dumb/details/busy';

export default function busyFactory(client) {
  return class DashboardManager extends React.Component {
    constructor(props) {
      super(props);
      this.state = {
        items: []
      };
      this.worker = props.match.params.name;
    }

    componentDidMount() {
      client
        .processing_data(this.worker)
        .then( items => this.setState({items}));
    }

    render() {
      return <Busy name={this.worker} {...this.state} />;
    }
  };
}
