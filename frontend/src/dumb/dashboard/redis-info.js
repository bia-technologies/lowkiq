import React from 'react';

function Card({title, val}) {
  return (
    <div className="card border-secondary">
      <div className="card-body text-secondary">
        <h5 className="card-title">{title}</h5>
        <div className="card-text">
          {val}
        </div>
      </div>
    </div>
  );
}

export default function RedisInfo(params) {
  const {
    url, version, uptime_in_days, connected_clients,
    used_memory_human, used_memory_peak_human
  } = params;
  return (
    <div>
      <h4>Redis info</h4>
      <div>
        <Card title="Url" type="secondary" val={url} />
      </div>
      <div className="card-group my-3">
        <Card title="Version"
              val={version} />
        <Card title="Uptime in days"
              val={uptime_in_days} />
        <Card title="Connected clients"
              val={connected_clients} />
        <Card title="Used memory"
              val={used_memory_human} />
        <Card title="Used memory peak"
              val={used_memory_peak_human} />
      </div>
    </div>
  );
}
