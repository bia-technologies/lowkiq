import React from 'react';

import Breadcrumbs from '../util/breadcrumbs';
import Filter from './filter';
import Job from './job';

export default function Enqueued({name, items,
                                  onPerformAllJobsNow, onKillAllFailedJobs, onDeleteAllFailedJobs,
                                  onFilter, selectedFilter}) {
  return (
    <div className="container">

      <Breadcrumbs name={name}
                   page="Enqueued" />

      <Filter label="id"
              type="text"
              selected={selectedFilter.id}
              onClick={onFilter.bind(null, "id")} />
      <Filter label="perform_in"
              type="number"
              selected={selectedFilter.perform_in}
              onClick={onFilter.bind(null, "perform_in")} />
      <Filter label="retry_count"
              type="number"
              selected={selectedFilter.retry_count}
              onClick={onFilter.bind(null, "retry_count")} />

      <div className="mb-3">
        <button className="btn btn-outline-primary mr-2"
                onClick={onPerformAllJobsNow}>
          perform all jobs now
        </button>

        <button className="btn btn-outline-danger mr-2"
                onClick={onKillAllFailedJobs}>
          kill all failed jobs
        </button>

        <button className="btn btn-outline-danger mr-2"
                onClick={onDeleteAllFailedJobs}>
          delete all failed jobs
        </button>
      </div>

      {items.map(item => {
        return <Job key={item.id} {...item} />;
      })}
    </div>
  );
}
