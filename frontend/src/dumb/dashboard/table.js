import React from 'react';
import { Link } from "react-router-dom";
import { OverlayTrigger, Tooltip } from 'react-bootstrap';

import formatNumber from '../util/format-number';
import formatDuration from '../util/format-duration';
import {RoutesContext} from '../routes';

function CamelCaseBreaker({val}) {
  return val
    .replace(/([a-z0-9:])([A-Z])/g, '$1 $2')
    .split(/\s/)
    .reduce((acc, word) => acc.concat(word, <wbr key={word}/>), []);
}

function FormattedNumber({val}) {
  return (
    <OverlayTrigger overlay={<Tooltip>{val.toLocaleString()}</Tooltip>} >
      <span>
        {formatNumber(val)}
      </span>
    </OverlayTrigger>
  );
}

function FormattedDuration({val}) {
  return (
    <OverlayTrigger overlay={<Tooltip>{val.toLocaleString()}</Tooltip>} >
      <span>
        {formatDuration(val)}
      </span>
    </OverlayTrigger>
  );
}

function Row({name, lag, processed, failed, busy, enqueued, fresh, retries, dead, routes}) {
  return (
    <tr>
      <td><CamelCaseBreaker val={name}/></td>
      <td>
        <FormattedNumber val={processed} />
      </td>
      <td>
        <FormattedNumber val={failed} />
      </td>
      <td>
        <FormattedDuration val={lag} />
      </td>
      <td>
        <Link to={routes.busy(name)}>
          {formatNumber(busy)}
        </Link>
      </td>
      <td>
        <Link to={{
                pathname: routes.enqueued(name)
              }}>
          {formatNumber(enqueued)}
        </Link>
      </td>
      <td>
        <Link to={{
                pathname: routes.enqueued(name),
                state: {selectedFilter: {retry_count: {min: '-inf', max: '-1', rev: true}}}
              }}>
          {formatNumber(fresh)}
        </Link>
      </td>
      <td>
        <Link to={{
                pathname: routes.enqueued(name),
                state: {selectedFilter: {retry_count: {min: '0', max: '+inf', rev: false}}}
              }}>
          {formatNumber(retries)}
        </Link>
      </td>
      <td>
        <Link to={routes.dead(name)}>
          {formatNumber(dead)}
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
