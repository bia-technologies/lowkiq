import React from 'react';
import { Redirect } from "react-router-dom";

import { RoutesContext } from '../routes';

export function RedirectToDashboard() {
  return (
    <RoutesContext.Consumer>
      {
        routes => <Redirect to={routes.dashboard()} />
      }
    </RoutesContext.Consumer>
  );
}
