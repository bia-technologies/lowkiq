import React from 'react';

export class Routes {
  constructor(rootUrl) {
    this.rootUrl = rootUrl;
  }

  dashboard() {
    return `${this.rootUrl}/`;
  }

  busy(queue) {
    return `${this.rootUrl}/${queue}/busy`;
  }

  enqueued(queue) {
    return `${this.rootUrl}/${queue}/enqueued`;
  }

  dead(queue) {
    return `${this.rootUrl}/${queue}/dead`;
  }
}

export const RoutesContext = React.createContext();
