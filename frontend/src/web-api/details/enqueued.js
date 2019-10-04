import React from 'react';
import _get from 'lodash/get';

import Enqueued from '../../dumb/details/enqueued';
import { RedirectToDashboard } from '../../dumb/util/redirect';

export default function enqueuedFactory(client) {
  return class EnqueuedManager extends React.Component {
    constructor(props) {
      super(props);

      const selectedFilter = _get(
        props,
        'location.state.selectedFilter',
        {id: {min: '-inf', max: '+inf', rev: false}}
      );

      this.state = {
        items: [],
        selectedFilter: selectedFilter
      };
      this.worker = props.match.params.name;
      this.handleFilter = this.handleFilter.bind(this);
      this.handlePerformAllJobsNow = this.handlePerformAllJobsNow.bind(this);
      this.handleKillAllFailedJobs = this.handleKillAllFailedJobs.bind(this);
      this.handleDeleteAllFailedJobs = this.handleDeleteAllFailedJobs.bind(this);
    }

    fetch(filter) {
      return client
        .filter(this.worker, filter)
        .then( items => this.setState({items, selectedFilter: filter}));
    }

    componentDidMount() {
      this.fetch(this.state.selectedFilter);
    }

    handleFilter(column, interval) {
      this.fetch({
        [column]: interval
      });
    }

    // действия происходят в бэкенде в отдельном треде
    handlePerformAllJobsNow() {
      if (! confirm("Are you sure?") ) return;
      client
        .perform_all_jobs_now(this.worker)
        .then(() => this.setState({toDashboard: true}));
    }

    // действия происходят в бэкенде в отдельном треде
    handleKillAllFailedJobs() {
      if (! confirm("Are you sure?") ) return;
      client
        .kill_all_failed_jobs(this.worker)
        .then(() => this.setState({toDashboard: true}));
    }

    // действия происходят в бэкенде в отдельном треде
    handleDeleteAllFailedJobs() {
      if (! confirm("Are you sure?") ) return;
      client
        .delete_all_failed_jobs(this.worker)
        .then(() => this.setState({toDashboard: true}));
    }

    render() {
      if (this.state.toDashboard) return <RedirectToDashboard />;

      return (
        <Enqueued name={this.worker}
                  onPerformAllJobsNow={this.handlePerformAllJobsNow}
                  onKillAllFailedJobs={this.handleKillAllFailedJobs}
                  onDeleteAllFailedJobs={this.handleDeleteAllFailedJobs}
                  onFilter={this.handleFilter}
                  {...this.state} />
      );
    }
  };
}
