import React from 'react';

import Breadcrumbs from '../util/breadcrumbs';
import Filter from './filter';
import Job from './job';

export default function Enqueued({name, items}) {
  return (
    <div className="container">

      <Breadcrumbs name={name}
                   page="Busy" />
      {items.map(item => {
        return <Job key={item.id} {...item} />;
      })}
    </div>
  );
}
