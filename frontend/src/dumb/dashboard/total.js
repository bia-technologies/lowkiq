import React from 'react';
import formatNumber from '../util/format-number';
import formatDuration from '../util/format-duration';

function Card({title, type, children}) {
  return (
    <div className={`card border-secondary`}>
      <div className={`card-body text-${type}`}>
        <h5 className="card-title">{title}</h5>
        <div className="card-text">
          {children}
        </div>
      </div>
    </div>
  );
}

export default function Total({ processed, failed, lag, busy, enqueued, fresh, retries, dead }) {
  return (
    <div className="card-group">
      <Card title="Lag"        type="secondary">{formatDuration(lag)}</Card>
      <Card title="Busy"       type="secondary">{formatNumber(busy)}</Card>
      <Card title="Enqueued"   type="secondary">{formatNumber(enqueued)}</Card>
      <Card title="Fresh"      type="secondary">{formatNumber(fresh)}</Card>
      <Card title="Retries"    type="secondary">{formatNumber(retries)}</Card>
      <Card title="Dead"       type="secondary">{formatNumber(dead)}</Card>
    </div>
  );
}
