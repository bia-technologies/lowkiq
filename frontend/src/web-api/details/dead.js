import React from 'react';

import Dead from '../../dumb/details/dead';
import { RedirectToDashboard } from '../../dumb/util/redirect';

export default function deadFactory(client) {
  return class DashboardManager extends React.Component {
    constructor(props) {
      super(props);
      this.state = {
        items: [],
        selectedFilter: {id: {min: '-inf', max: '+inf', rev: false}}
      };
      this.worker = props.match.params.name;

      this.handleFilter = this.handleFilter.bind(this);
      this.handleQueueUp = this.handleQueueUp.bind(this);
      this.handleDelete = this.handleDelete.bind(this);
      this.handleQueueUpAllJobs = this.handleQueueUpAllJobs.bind(this);
      this.handleDeleteAllJobs = this.handleDeleteAllJobs.bind(this);
    }

    // действия происходят в бэкенде в отдельном треде
    handleQueueUp(id) {
      client
        .morgue_queue_up(this.worker, id)
        .then(() => this.setState(state => {
          const items = state.items.filter( item => item.id !== id );
          return {items};
        }));
    }

    // действия происходят в бэкенде в отдельном треде
    handleDelete(id) {
      client
        .morgue_delete(this.worker, id)
        .then(() => this.setState(state => {
          const items = state.items.filter( item => item.id !== id );
          return {items};
        }));
    }

    // действия происходят в бэкенде в отдельном треде
    handleQueueUpAllJobs() {
      if (! confirm("Are you sure?") ) return;
      client
        .morgue_queue_up_all_jobs(this.worker)
        .then(() => this.setState({toDashboard: true}));
    }

    // действия происходят в бэкенде в отдельном треде
    handleDeleteAllJobs() {
      if (! confirm("Are you sure?") ) return;
      client
        .morgue_delete_all_jobs(this.worker)
        .then(() => this.setState({toDashboard: true}));
    }

    fetch(filter) {
      return client
        .morgue_filter(this.worker, filter)
        .then( items => items.map((item) => {
          item.actions = {
            onQueueUp: () => this.handleQueueUp(item.id),
            onDelete:  () => this.handleDelete(item.id)
          };
          return item;
        }))
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

    render() {
      if (this.state.toDashboard) return <RedirectToDashboard />;

      return (
        <Dead name={this.worker}
              onFilter={this.handleFilter}
              onQueueUpAllJobs={this.handleQueueUpAllJobs}
              onDeleteAllJobs={this.handleDeleteAllJobs}
              {...this.state} />
      );
    }
  };
}
