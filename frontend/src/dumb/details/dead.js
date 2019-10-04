import React from 'react';

import Breadcrumbs from '../util/breadcrumbs';
import Filter from './filter';
import Job from './job';

export default function Dead(props) {
  const {
    name, items,
    onFilter, selectedFilter,
    onQueueUpAllJobs, onDeleteAllJobs
  } = props;
  return (
    <div className="container">

      <Breadcrumbs name={name}
                   page="Dead" />

      <Filter label="id"
              type="text"
              selected={selectedFilter.id}
              onClick={onFilter.bind(null, "id")} />
      <Filter label="updated_at"
              type="number"
              selected={selectedFilter.updated_at}
              onClick={onFilter.bind(null, "updated_at")} />

      <div className="mb-3">
        <button className="btn btn-outline-primary mr-2"
                onClick={onQueueUpAllJobs}>
          queue up all jobs
        </button>
        <button className="btn btn-outline-danger"
                onClick={onDeleteAllJobs}>
          delete all jobs
        </button>
      </div>

      {items.map(item => {
        return <Job key={item.id} {...item} />;
      })}
    </div>
  );
}
