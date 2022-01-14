import React from 'react';
import classNames from 'classnames';
import style from './job.module.css';

function isPresent(val) {
  return val !== null && val !== undefined && val !== '';
}

function Meta({label, value}) {
  return (
    <tr>
      <th>{label}</th>
      <td>{value}</td>
    </tr>
  );
}

function Payload({payload, score}) {
  return [
    (
      <Meta key="score" label="score" value={score} />
    ), (
      <tr key="payload">
        <th>payload</th>
        <td>
          <pre className="mb-0">
            {JSON.stringify(payload, null, 2)}
          </pre>
        </td>
      </tr>
    )
  ];
}

function Actions({onQueueUp, onDelete}) {
  return (
    <tr>
      <th>
        actions
      </th>
      <td>
        <button className="btn btn-outline-primary mr-2"
                onClick={onQueueUp}>
          queue up
        </button>
        <button className="btn btn-outline-danger"
                onClick={onDelete}>
          delete
        </button>
      </td>
    </tr>
  );
}

function time(timestamp) {
  const time = new Date(timestamp * 1000).toLocaleString();
  return `${timestamp} [${time}]`;
}

function fmtRetryCount(val) {
  if (val === -1) return `${val} [fresh]`;
  if (val >= 0) return `${val} [retry]`;
  return val;
}

export default function Job(props) {
  const {
    id, perform_in, retry_count, updated_at, error, payloads,
    actions
  } = props;
  const tableClasses = classNames(
    'table',
    'table-bordered',
    style.table
  );
  return (
    <table className={tableClasses}>
      <colgroup>
        <col className={style.label} />
        <col className={style.value} />
      </colgroup>
      <tbody>
        {isPresent(id)          && <Meta label="id"          value={id}          />}
        {isPresent(perform_in)  && <Meta label="perform_in"  value={time(perform_in)}  />}
        {isPresent(retry_count) && <Meta label="retry_count" value={fmtRetryCount(retry_count)} />}
        {isPresent(updated_at)  && <Meta label="updated_at"  value={time(updated_at)}  />}
        {isPresent(error)       && <Meta label="error"       value={<pre>error</pre>} />}
        {payloads.map(([payload, score]) => {
          return <Payload key={score} score={time(score)} payload={payload} />;
        })}
        {actions && <Actions {...actions} />}
      </tbody>
    </table>
  );
}
