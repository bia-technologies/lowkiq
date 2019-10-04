import React from 'react';
import Num from '../util/num';
import Duration from '../util/duration';

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
      {/* <Card title="Processed"  type="success"   val={ processed } /> */}
      {/* <Card title="Failed"     type="danger"    val={ failed } /> */}
      <Card title="Lag"        type="secondary"><Duration val={ lag } /></Card>
      <Card title="Busy"       type="secondary"><Num val={busy} /></Card>
      <Card title="Enqueued"   type="secondary"><Num val={enqueued} /></Card>
      <Card title="Fresh"      type="secondary"><Num val={fresh} /></Card>
      <Card title="Retries"    type="secondary"><Num val={retries} /></Card>
      <Card title="Dead"       type="secondary"><Num val={dead} /></Card>
    </div>
  );
}
