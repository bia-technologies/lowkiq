import React from 'react';
import { Link } from "react-router-dom";

import Num from '../util/num';
import Duration from '../util/duration';
import {RoutesContext} from '../routes';

function CamelCaseBreaker({val}) {
  return val
    .replace(/([a-z0-9:])([A-Z])/g, '$1 $2')
    .split(/\s/)
    .reduce((acc, word) => acc.concat(word, <wbr key={word}/>), []);
}

function Row({name, lag, processed, failed, busy, enqueued, fresh, retries, dead, routes}) {
  return (
    <tr>
      <td><CamelCaseBreaker val={name}/></td>
      <td><Num val={processed} /></td>
      <td><Num val={failed} /></td>
      <td><Duration val={lag} /></td>
      <td>
        <Link to={routes.busy(name)}>
          <Num val={busy} />
        </Link>
      </td>
      <td>
        <Link to={{
                pathname: routes.enqueued(name)
              }}>
          <Num val={enqueued} />
        </Link>
      </td>
      <td>
        <Link to={{
                pathname: routes.enqueued(name),
                state: {selectedFilter: {retry_count: {min: '-inf', max: '-1', rev: true}}}
              }}>
          <Num val={fresh} />
        </Link>
      </td>
      <td>
        <Link to={{
                pathname: routes.enqueued(name),
                state: {selectedFilter: {retry_count: {min: '0', max: '+inf', rev: false}}}
              }}>
          <Num val={retries} />
        </Link>
      </td>
      <td>
        <Link to={routes.dead(name)}>
          <Num val={dead} />
        </Link>
      </td>
    </tr>
  );
}

export default function Table({queues}) {
  return (
    <div className="table-responsive">
      <table className="table">
        <thead>
          <tr>
            <th scope="col">Worker</th>
            <th scope="col">Processed</th>
            <th scope="col">Failed</th>
            <th scope="col">Lag</th>
            <th scope="col">Busy</th>
            <th scope="col">Enqueued</th>
            <th scope="col">Fresh</th>
            <th scope="col">Retries</th>
            <th scope="col">Dead</th>
          </tr>
        </thead>
        <tbody>
          {
            queues.map( queue => {
              return <RoutesContext.Consumer key={queue.name}>
                {routes => <Row routes={routes} {...queue} />}
              </RoutesContext.Consumer>;
            })
          }
        </tbody>
      </table>
    </div>
  );
}
