import ky from 'ky';

function prepareMinMax(column, [min, max]) {
  let c_min, c_max;

  if (column === 'id') {
    if (min === '-inf') {
      c_min = '-';
    } else {
      c_min = '[' + min;
    }
  } else {
    c_min = min.toString();
  }

  if (column === 'id') {
    if (max === '+inf') {
      c_max = '+';
    } else {
      c_max = '[' + max;
    }
  } else {
    c_max = max.toString();
  }

  return [c_min, c_max];
}

export default class Routes {
  constructor(baseUrl, opts = {}) {
    this.api = ky.extend({prefixUrl: baseUrl, ...opts});
  }

  dashboard() {
    return this.api.get('dashboard')
      .then(resp => resp.json());
  }

  processing_data(worker) {
    return this.api
      .get(`${worker}/processing_data`)
      .then(resp => resp.json());
  }

  filter(worker, filter) {
    const [column, {rev, min, max}] = Object.entries(filter)[0];
    const [c_min, c_max] = prepareMinMax(column, [min, max]);
    const path = `${worker}/${rev ? 'rev_' : ''}range_by_${column}`;

    return this.api
      .get(path, {searchParams: {min: c_min, max: c_max}})
      .then(resp => resp.json());
  }

  morgue_filter(worker, filter) {
    const [column, {rev, min, max}] = Object.entries(filter)[0];
    const [c_min, c_max] = prepareMinMax(column, [min, max]);
    const path = `${worker}/morgue_${rev ? 'rev_' : ''}range_by_${column}`;

    return this.api
      .get(path, {searchParams: {min: c_min, max: c_max}})
      .then(resp => resp.json());
  }

  morgue_queue_up(worker, id) {
    return this.api
      .post(`${worker}/morgue_queue_up?ids[]=${id}`)
      .then(() => null);
  }

  morgue_delete(worker, id) {
    return this.api
      .post(`${worker}/morgue_delete?ids[]=${id}`)
      .then(() => null);
  }

  morgue_queue_up_all_jobs(worker) {
    return this.api
      .post(`${worker}/morgue_queue_up_all_jobs`)
      .then(() => null);
  }

  morgue_delete_all_jobs(worker) {
    return this.api
      .post(`${worker}/morgue_delete_all_jobs`)
      .then(() => null);
  }

  perform_all_jobs_now(worker) {
    return this.api
      .post(`${worker}/perform_all_jobs_now`)
      .then(() => null);
  }

  kill_all_failed_jobs(worker) {
    return this.api
      .post(`${worker}/kill_all_failed_jobs`)
      .then(() => null);
  }

  delete_all_failed_jobs(worker) {
    return this.api
      .post(`${worker}/delete_all_failed_jobs`)
      .then(() => null);
  }
}
